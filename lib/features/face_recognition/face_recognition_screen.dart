import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        const Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(child: _ResultPanel()),
        ),
      ],
    );
  }
}

/// Name and accuracy of the person in view, shown as plain text at the bottom.
/// Watches only the result and notice, so a new frame rebuilds just this.
class _ResultPanel extends ConsumerWidget {
  const _ResultPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(recognitionProvider.select((s) => s.result));
    final message = ref.watch(recognitionProvider.select((s) => s.message));
    final textTheme = Theme.of(context).textTheme;

    final Widget content;
    if (result != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.name,
            style: textTheme.headlineMedium?.copyWith(
              color: result.isMatch ? Colors.greenAccent : Colors.orangeAccent,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Accuracy: ${result.percentage.toStringAsFixed(0)}%',
            style: textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      );
    } else {
      content = Text(
        message ?? '',
        style: textTheme.titleMedium?.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
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
