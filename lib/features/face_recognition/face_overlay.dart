import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'face_overlay_geometry.dart';
import 'face_overlay_painter.dart';
import 'recognition_notifier.dart';

/// The box + name label over the camera preview.
///
/// Watches only the tracked face, so a new detection repaints this layer and
/// nothing else, and animates between successive boxes so the overlay glides
/// with the face instead of jumping at the detector's frame rate.
class FaceOverlay extends ConsumerWidget {
  const FaceOverlay({super.key, required this.previewSize});

  final Size previewSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final face = ref.watch(recognitionProvider.select((s) => s.face));
    if (face == null || face.frameSize.isEmpty) return const SizedBox.shrink();

    // `frameSize` is the size of the frame ML Kit actually measured against
    // (rotated upright on Android; raw, un-rotated sensor space on iOS —
    // google_mlkit_commons ignores the rotation hint there). On Android this
    // already matches CameraPreview's upright orientation. On iOS the box
    // stays in sensor (landscape) space while CameraPreview renders upright —
    // verify on an iOS device and rotate the box there too if the overlay
    // appears sideways.
    final target = scaleRect(face.box, face.frameSize, previewSize);
    return RepaintBoundary(
      child: TweenAnimationBuilder<Rect?>(
        tween: RectTween(end: target),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, box, _) => CustomPaint(
          size: Size.infinite,
          painter: FaceOverlayPainter(
            box: box ?? target,
            label: face.label,
            isMatch: face.isMatch,
          ),
        ),
      ),
    );
  }
}
