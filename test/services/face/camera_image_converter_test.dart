import 'dart:typed_data';

import 'package:face_recognition_app_1/services/face/camera_image_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 4x2 NV21 frame: 8 luma bytes then 2 interleaved VU pairs.
  final nv21 = Uint8List.fromList([...List.filled(8, 128), 128, 128, 128, 128]);

  test('NV21 frame keeps its size when no rotation is requested', () {
    final image = imageFromFrameBytes(
      bytes: nv21,
      width: 4,
      height: 2,
      bytesPerRow: 4,
      isIOS: false,
      rotationDegrees: 0,
    );
    expect((image.width, image.height), (4, 2));
  });

  test('NV21 frame is rotated into ML Kit\'s upright space at 90 degrees', () {
    final image = imageFromFrameBytes(
      bytes: nv21,
      width: 4,
      height: 2,
      bytesPerRow: 4,
      isIOS: false,
      rotationDegrees: 90,
    );
    expect((image.width, image.height), (2, 4));
  });

  test('NV21 neutral chroma decodes to the luma value on every channel', () {
    final gray = Uint8List.fromList([
      ...List.filled(8, 100),
      128, 128, 128, 128,
    ]);
    final image = imageFromFrameBytes(
      bytes: gray,
      width: 4,
      height: 2,
      bytesPerRow: 4,
      isIOS: false,
      rotationDegrees: 0,
    );
    final px = image.getPixel(2, 1);
    expect((px.r, px.g, px.b), (100, 100, 100));
  });

  test('NV21 saturated red chroma decodes to a red pixel', () {
    final red = Uint8List.fromList([
      ...List.filled(8, 82),
      240, 90, 240, 90, // V high, U low
    ]);
    final image = imageFromFrameBytes(
      bytes: red,
      width: 4,
      height: 2,
      bytesPerRow: 4,
      isIOS: false,
      rotationDegrees: 0,
    );
    final px = image.getPixel(0, 0);
    expect(px.r, greaterThan(200));
    expect(px.g, lessThan(60));
    expect(px.b, lessThan(60));
  });
}
