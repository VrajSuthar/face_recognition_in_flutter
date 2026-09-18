import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/face/camera_image_converter.dart';
import '../../services/face/face_crop.dart';
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
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);
  Rect? _boxSensorSpace;
  Size _sensorSize = Size.zero;
  String? _label;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final repository = await ref.read(faceRepositoryProvider.future);
    final entries = await repository.loadAll();
    if (!mounted) return;
    if (entries.isEmpty) {
      setState(() => _statusMessage = 'Register a face first.');
      return;
    }

    final cameras = await availableCameras();
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
          _boxSensorSpace = null;
          _label = null;
          _statusMessage = 'No face detected';
        });
        return;
      }

      final rawImage = imageFromCameraImage(image);
      final cropped = cropFaceSquare(rawImage, face.boundingBox, size: _embedSize);

      final embedder = await ref.read(faceEmbedderServiceProvider.future);
      final embedding = embedder.embed(cropped);

      final repository = await ref.read(faceRepositoryProvider.future);
      final entries = await repository.loadAll();
      final match = bestMatch(embedding, entries);
      if (!mounted) return;

      setState(() {
        _boxSensorSpace = face.boundingBox;
        _sensorSize = Size(image.width.toDouble(), image.height.toDouble());
        _statusMessage = null;
        _label = match == null
            ? null
            : '${match.isMatch ? match.name : 'Unknown'} — ${match.percentage.round()}%';
      });
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: controller == null || !controller.value.isInitialized
          ? Center(child: Text(_statusMessage ?? 'Loading…'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final previewSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    // NOTE: verify on device — if the box appears rotated
                    // 90 degrees relative to the visible face, swap
                    // `_sensorSize`'s width/height here to match how
                    // CameraPreview rotates the raw sensor frame for display.
                    if (_boxSensorSpace != null && _sensorSize != Size.zero)
                      CustomPaint(
                        painter: FaceOverlayPainter(
                          box: scaleRect(
                              _boxSensorSpace!, _sensorSize, previewSize),
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
