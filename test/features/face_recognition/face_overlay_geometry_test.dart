import 'dart:ui';

import 'package:face_recognition_app_1/features/face_recognition/face_overlay_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scales a rect proportionally between two sizes', () {
    const source = Rect.fromLTWH(10, 20, 30, 40);
    const fromSize = Size(100, 200);
    const toSize = Size(200, 400);

    final result = scaleRect(source, fromSize, toSize);

    expect(result.left, 20);
    expect(result.top, 40);
    expect(result.width, 60);
    expect(result.height, 80);
  });

  test('handles non-uniform scale factors', () {
    const source = Rect.fromLTWH(0, 0, 10, 10);
    const fromSize = Size(10, 10);
    const toSize = Size(50, 20);

    final result = scaleRect(source, fromSize, toSize);

    expect(result.width, 50);
    expect(result.height, 20);
  });
}
