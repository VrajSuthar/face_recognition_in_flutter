import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'face_overlay.dart';
import 'recognition_notifier.dart';
import 'recognition_state.dart';

class FaceRecognitionScreen extends ConsumerWidget {
  const FaceRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(recognitionProvider.select((s) => s.phase));
    final controller = ref.watch(
      recognitionProvider.select((s) => s.controller),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: phase == RecognitionPhase.running && controller != null
          ? _CameraView(controller: controller)
          : _StatusView(phase: phase),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            FaceOverlay(previewSize: previewSize),
            const Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: _NoticeChip(),
            ),
          ],
        );
      },
    );
  }
}

class _NoticeChip extends ConsumerWidget {
  const _NoticeChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(recognitionProvider.select((s) => s.message));
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: message == null
            ? const SizedBox.shrink()
            : Container(
                key: ValueKey(message),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}

class _StatusView extends ConsumerWidget {
  const _StatusView({required this.phase});

  final RecognitionPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(recognitionProvider.select((s) => s.message));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phase == RecognitionPhase.starting)
              const CircularProgressIndicator()
            else ...[
              Text(
                message ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: ref.read(recognitionProvider.notifier).start,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
