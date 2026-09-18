import 'dart:ui';

import 'package:face_recognition_app_1/services/face/face_crop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('crops and resizes to the requested square size', () {
    final source = img.Image(width: 200, height: 200);
    const box = Rect.fromLTWH(50, 50, 60, 60);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);
  });

  test('clamps the crop to the source image bounds near an edge', () {
    final source = img.Image(width: 100, height: 100);
    const box = Rect.fromLTWH(0, 0, 20, 20);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);
  });
}
