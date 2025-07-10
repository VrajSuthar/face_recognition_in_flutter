import 'package:flutter/material.dart';

class OvalPainter extends CustomPainter {
  final Rect oval;

  OvalPainter(this.oval);

  @override
  void paint(Canvas canvas, Size size) {
    // Create path with oval cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;

    // Draw dark overlay outside oval
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawPath(path, overlayPaint);

    // Optional: draw white border around oval
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(oval, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
