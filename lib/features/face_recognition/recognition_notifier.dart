import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/face/camera_image_converter.dart';
import '../../services/face/embedding_smoother.dart';
import '../../services/face/face_detector_service.dart';
import '../../services/face/face_entry.dart';
import '../../services/face/face_similarity.dart';
import '../../services/face/frame_cropper.dart';
import '../../services/face/providers.dart';
import 'recognition_state.dart';

const _embedSize = 112;

/// Consecutive detector misses tolerated before the result is dropped, so a
/// single missed detection doesn't make the text flicker to "No face".
const _missesBeforeClear = 3;

final recognitionProvider =
    NotifierProvider.autoDispose<RecognitionNotifier, RecognitionState>(
      RecognitionNotifier.new,
    );

class RecognitionNotifier extends Notifier<RecognitionState> {
  CameraController? _controller;
  bool _isStarting = false;
  bool _isBusy = false;
  int _misses = 0;

  /// Averages the last few frames' embeddings. Starts at one frame, so the
  /// first result appears immediately and firms up as more frames arrive.
  final _smoother = EmbeddingSmoother(window: 4);

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
      final all = await repository.loadAll();
      if (!ref.mounted) return;
      if (all.isEmpty) {
        _fail('Register a face first.');
        return;
      }
      final entries = all
          .where((e) => e.embeddingVersion == currentEmbeddingVersion)
          .toList();
      if (entries.isEmpty) {
        _fail(
          'Face matching was upgraded. Please register your faces again '
          'for better accuracy.',
        );
        return;
      }
      _entries = entries;

      // Load the model up front so the first frame isn't spent waiting on it.
      await ref.read(faceEmbedderServiceProvider.future);
      if (!ref.mounted) return;

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
      _smoother.reset();
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

  /// Runs every frame the pipeline is free to take — there is no time-based
  /// throttle. A frame that arrives while the previous one is still being
  /// processed is dropped (the camera delivers frames faster than detection +
  /// embedding can run, and queueing them would only add latency).
  Future<void> _onFrame(CameraImage image, CameraDescription camera) async {
    if (_isBusy || !ref.mounted) return;
    _isBusy = true;

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

      final cropped = await cropFaceInBackground(
        image,
        camera,
        face.boundingBox,
        size: _embedSize,
        isIOS: Platform.isIOS,
        landmarks: face.alignmentLandmarks,
      );
      if (!ref.mounted) return;
      final embedder = await ref.read(faceEmbedderServiceProvider.future);
      if (!ref.mounted) return;

      final match = bestMatch(_smoother.add(embedder.embed(cropped)), _entries);
      if (match == null) return;
      _emit(
        state.copyWith(
          clearMessage: true,
          result: RecognitionResult(
            name: match.isMatch ? match.name : 'Unknown',
            percentage: match.percentage,
            isMatch: match.isMatch,
          ),
        ),
      );
    } catch (e) {
      // Without this the exception would escape the image-stream callback on
      // every frame and the text would silently freeze.
      if (ref.mounted) {
        _emit(state.copyWith(message: 'Recognition error: $e'));
      }
    } finally {
      _isBusy = false;
    }
  }

  void _onNoFace() {
    _misses++;
    final hasResult = state.result != null;
    if (hasResult && _misses < _missesBeforeClear) return;
    if (!hasResult && state.message == _noFaceMessage) return;
    _smoother.reset();
    _emit(state.copyWith(clearResult: true, message: _noFaceMessage));
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
