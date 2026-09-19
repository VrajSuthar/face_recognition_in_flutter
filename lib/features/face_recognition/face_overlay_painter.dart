import 'package:flutter/material.dart';

class FaceOverlayPainter extends CustomPainter {
  const FaceOverlayPainter({
    required this.box,
    this.label,
    this.isMatch = false,
  });

  final Rect box;
  final String? label;
  final bool isMatch;

  @override
  void paint(Canvas canvas, Size size) {
    final color = isMatch ? Colors.greenAccent : Colors.orangeAccent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(14)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final label = this.label;
    if (label == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final pillWidth = textPainter.width + padding.horizontal;
    final pillHeight = textPainter.height + padding.vertical;
    final top = box.top - pillHeight - 6 < 0
        ? box.bottom + 6
        : box.top - pillHeight - 6;
    final left = box.left.clamp(
      0.0,
      (size.width - pillWidth).clamp(0.0, size.width),
    );
    final pill = Rect.fromLTWH(left, top, pillWidth, pillHeight);

    canvas.drawRRect(
      RRect.fromRectAndRadius(pill, const Radius.circular(12)),
      Paint()..color = color,
    );
    textPainter.paint(canvas, pill.topLeft + Offset(padding.left, padding.top));
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.box != box ||
        oldDelegate.label != label ||
        oldDelegate.isMatch != isMatch;
  }
}
