import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/face/camera_image_converter.dart';
import '../../services/face/face_entry.dart';
import '../../services/face/face_similarity.dart';
import '../../services/face/frame_cropper.dart';
import '../../services/face/providers.dart';
import 'recognition_state.dart';

const _embedSize = 112;

/// How often a frame is run through the (cheap) face detector to move the box.
const _detectEvery = Duration(milliseconds: 90);

/// How often the (costly) crop + embedding runs to refresh the name label.
const _recognizeEvery = Duration(milliseconds: 600);

/// Consecutive detector misses tolerated before the box is dropped, so a
/// single dropped frame doesn't make the overlay flicker off and on.
const _missesBeforeClear = 5;

final recognitionProvider =
    NotifierProvider.autoDispose<RecognitionNotifier, RecognitionState>(
      RecognitionNotifier.new,
    );

class RecognitionNotifier extends Notifier<RecognitionState> {
  CameraController? _controller;
  bool _isStarting = false;
  bool _isBusy = false;
  DateTime _lastDetect = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRecognize = DateTime.fromMillisecondsSinceEpoch(0);
  int _misses = 0;

  /// Registered faces, loaded once per start rather than re-read from disk on
  /// every inference.
  List<FaceEntry> _entries = const [];

  @override
  RecognitionState build() {
    // v1: locked to portrait to avoid needing full sensorOrientation +
    // deviceOrientation rotation compensation (see google_mlkit_commons docs).
    // TODO: support device rotation by combining sensorOrientation with
    // the live deviceOrientation per lens direction.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    ref.onDispose(() {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      _releaseController();
    });
    Future.microtask(start);
    return const RecognitionState();
  }

  /// Safe to call again (the retry button): a second call while one is in
  /// flight is ignored.
  Future<void> start() async {
    if (_isStarting || !ref.mounted) return;
    _isStarting = true;
    try {
      await _releaseController();
      _emit(const RecognitionState());

      final repository = await ref.read(faceRepositoryProvider.future);
      final entries = await repository.loadAll();
      if (!ref.mounted) return;
      if (entries.isEmpty) {
        _fail('Register a face first.');
        return;
      }
      _entries = entries;

      final List<CameraDescription> cameras;
      try {
        cameras = await availableCameras();
      } catch (e) {
        _fail('Could not access the camera: $e');
        return;
      }
      if (cameras.isEmpty) {
        _fail('No camera available on this device.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      try {
        await controller.initialize();
      } catch (e) {
        await _safeDispose(controller);
        _fail('Could not start the camera: $e');
        return;
      }
      if (!ref.mounted) {
        await _safeDispose(controller);
        return;
      }

      _controller = controller;
      _misses = 0;
      _emit(
        RecognitionState(
          phase: RecognitionPhase.running,
          message: null,
          controller: controller,
        ),
      );
      await controller.startImageStream((image) => _onFrame(image, camera));
    } catch (e) {
      // A corrupted faces index, a failing provider, an image stream that
      // refuses to start: all must surface rather than leave the screen stuck
      // on "Starting camera…".
      _fail('Could not start recognition: $e');
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _onFrame(CameraImage image, CameraDescription camera) async {
    if (_isBusy || !ref.mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastDetect) < _detectEvery) return;
    _isBusy = true;
    _lastDetect = now;

    try {
      final inputImage = inputImageFromCameraImage(image, camera);
      if (inputImage == null) return;

      final face = await ref
          .read(faceDetectorServiceProvider)
          .detectLargestFace(inputImage);
      if (!ref.mounted) return;

      if (face == null) {
        _onNoFace();
        return;
      }
      _misses = 0;

      // Publish the box straight away, keeping the previous label, so the
      // overlay tracks at detector speed instead of waiting on recognition.
      final previous = state.face;
      _emit(
        state.copyWith(
          clearMessage: true,
          face: TrackedFace(
            box: face.boundingBox,
            frameSize: detectionSizeFor(image, camera),
            label: previous?.label,
            isMatch: previous?.isMatch ?? false,
          ),
        ),
      );

      if (now.difference(_lastRecognize) < _recognizeEvery) return;
      _lastRecognize = now;

      final cropped = await cropFaceInBackground(
        image,
        camera,
        face.boundingBox,
        size: _embedSize,
        isIOS: Platform.isIOS,
      );
      if (!ref.mounted) return;
      final embedder = await ref.read(faceEmbedderServiceProvider.future);
      if (!ref.mounted) return;

      final match = bestMatch(embedder.embed(cropped), _entries);
      final current = state.face;
      if (match == null || current == null) return;
      _emit(
        state.copyWith(
          face: current.copyWith(
            label:
                '${match.isMatch ? match.name : 'Unknown'} — ${match.percentage.round()}%',
            isMatch: match.isMatch,
          ),
        ),
      );
    } catch (e) {
      // Without this the exception would escape the image-stream callback on
      // every frame and the overlay would silently freeze.
      if (ref.mounted) {
        _emit(state.copyWith(message: 'Recognition error: $e'));
      }
    } finally {
      _isBusy = false;
    }
  }

  void _onNoFace() {
    _misses++;
    final hasFace = state.face != null;
    if (hasFace && _misses < _missesBeforeClear) return;
    if (!hasFace && state.message == _noFaceMessage) return;
    // Start the next appearance from a clean label rather than the last
    // person's.
    _lastRecognize = DateTime.fromMillisecondsSinceEpoch(0);
    _emit(state.copyWith(clearFace: true, message: _noFaceMessage));
  }

  static const _noFaceMessage = 'No face detected';

  void _fail(String message) {
    _emit(RecognitionState(phase: RecognitionPhase.error, message: message));
  }

  void _emit(RecognitionState next) {
    if (ref.mounted) state = next;
  }

  Future<void> _releaseController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    // `stopImageStream` throws when the controller is not streaming (e.g.
    // disposed between `initialize()` and `startImageStream()`), and cleanup
    // must never throw.
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream().catchError((Object _) {});
    }
    await _safeDispose(controller);
  }

  Future<void> _safeDispose(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (_) {
      // Already failed or disposed; we're discarding it either way.
    }
  }
}
