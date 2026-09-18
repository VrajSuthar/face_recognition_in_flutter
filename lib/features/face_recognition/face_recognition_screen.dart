import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/face/camera_image_converter.dart';
import '../../services/face/face_crop.dart';
import '../../services/face/face_entry.dart';
import '../../services/face/face_similarity.dart';
import '../../services/face/providers.dart';
import 'face_overlay_geometry.dart';
import 'face_overlay_painter.dart';

const _throttle = Duration(milliseconds: 700);
const _embedSize = 112;

class FaceRecognitionScreen extends ConsumerStatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  ConsumerState<FaceRecognitionScreen> createState() =>
      _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends ConsumerState<FaceRecognitionScreen> {
  CameraController? _controller;
  String? _statusMessage = 'Starting camera…';
  bool _isBusy = false;
  bool _isStarting = false;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);
  Rect? _boxDetectionSpace;
  Size _detectionSize = Size.zero;
  String? _label;

  /// Registered faces, loaded once on screen entry (see `_start`) rather than
  /// re-read from disk on every inference.
  List<FaceEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    // v1: locked to portrait to avoid needing full sensorOrientation +
    // deviceOrientation rotation compensation (see google_mlkit_commons docs).
    // TODO: support device rotation by combining sensorOrientation with
    // the live deviceOrientation per lens direction.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _start();
  }

  Future<void> _start() async {
    // Guard against re-entry (e.g. a double tap on the retry button) and
    // make this method safely re-runnable from the retry button.
    if (_isStarting) return;
    _isStarting = true;
    // Safe on both entry paths: Flutter explicitly tolerates `setState` from
    // `initState` (the first build is already scheduled), and a Retry tap is
    // an ordinary post-build state change that does need a rebuild.
    setState(() => _statusMessage = 'Starting camera…');
    try {
      final repository = await ref.read(faceRepositoryProvider.future);
      final entries = await repository.loadAll();
      if (!mounted) return;
      if (entries.isEmpty) {
        setState(() => _statusMessage = 'Register a face first.');
        return;
      }
      _entries = entries;

      List<CameraDescription> cameras;
      try {
        cameras = await availableCameras();
      } catch (e) {
        if (!mounted) return;
        setState(() => _statusMessage = 'Could not access the camera: $e');
        return;
      }
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _statusMessage = 'No camera available on this device.');
        return;
      }
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );

      try {
        await controller.initialize();
      } catch (e) {
        try {
          await controller.dispose();
        } catch (_) {
          // The controller already failed to initialize; ignore any
          // secondary error from disposing it — we're discarding it either way.
        }
        if (!mounted) return;
        setState(() => _statusMessage = 'Could not start the camera: $e');
        return;
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _statusMessage = null;
      });

      await controller.startImageStream((image) => _onFrame(image, frontCamera));
    } catch (e) {
      // Anything unexpected (a corrupted faces index, a failing provider, the
      // image stream refusing to start) must still surface in the UI —
      // otherwise the screen is stuck on "Starting camera…" forever.
      if (mounted) {
        setState(() => _statusMessage = 'Could not start recognition: $e');
      }
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _onFrame(CameraImage image, CameraDescription camera) async {
    if (_isBusy || !mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastRun) < _throttle) return;
    _isBusy = true;
    _lastRun = now;

    try {
      final inputImage = inputImageFromCameraImage(image, camera);
      if (inputImage == null) return;

      final detector = ref.read(faceDetectorServiceProvider);
      final face = await detector.detectLargestFace(inputImage);
      if (!mounted) return;

      if (face == null) {
        setState(() {
          _boxDetectionSpace = null;
          _label = null;
          _statusMessage = 'No face detected';
        });
        return;
      }

      // Same coordinate space as `face.boundingBox` by construction — see
      // `imageFromCameraImage`.
      final frame = imageFromCameraImage(image, camera);
      final cropped = cropFaceSquare(frame, face.boundingBox, size: _embedSize);

      final embedder = await ref.read(faceEmbedderServiceProvider.future);
      if (!mounted) return;
      final embedding = embedder.embed(cropped);

      final match = bestMatch(embedding, _entries);
      if (!mounted) return;

      setState(() {
        _boxDetectionSpace = face.boundingBox;
        _detectionSize =
            Size(frame.width.toDouble(), frame.height.toDouble());
        _statusMessage = null;
        _label = match == null
            ? null
            : '${match.isMatch ? match.name : 'Unknown'} — ${match.percentage.round()}%';
      });
    } catch (e) {
      // Without this the exception would escape the image-stream callback
      // roughly every 700ms and the overlay would just silently freeze.
      if (mounted) {
        setState(() => _statusMessage = 'Recognition error: $e');
      }
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      // `stopImageStream` throws a CameraException when the controller is not
      // currently streaming (e.g. disposed between `initialize()` and
      // `startImageStream()`), and `dispose()` must never throw.
      if (controller.value.isStreamingImages) {
        controller.stopImageStream().catchError((Object _) {});
      }
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: controller == null || !controller.value.isInitialized
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_statusMessage ?? 'Loading…'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _start,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final previewSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    // `_detectionSize` is the size of the frame ML Kit
                    // actually measured against (rotated upright on Android,
                    // raw on iOS), so it is already in the same upright
                    // orientation CameraPreview displays — no width/height
                    // swap is needed here.
                    if (_boxDetectionSpace != null &&
                        _detectionSize != Size.zero)
                      CustomPaint(
                        painter: FaceOverlayPainter(
                          box: scaleRect(
                              _boxDetectionSpace!, _detectionSize, previewSize),
                          label: _label,
                        ),
                      ),
                    if (_statusMessage != null)
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: Colors.black54,
                            child: Text(
                              _statusMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
