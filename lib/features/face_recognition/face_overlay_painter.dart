import 'package:flutter/material.dart';

class FaceOverlayPainter extends CustomPainter {
  const FaceOverlayPainter({required this.box, this.label});

  final Rect box;
  final String? label;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(box, paint);

    final label = this.label;
    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(box.left, (box.top - textPainter.height - 4).clamp(0, size.height)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.box != box || oldDelegate.label != label;
  }
}
