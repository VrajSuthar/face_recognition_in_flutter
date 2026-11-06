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

  test('BGRA frame that is a view into a larger buffer decodes from its offset', () {
    // Platform-channel bytes are views into the message buffer; an odd offset
    // like this one would misalign every channel if it were ignored.
    final backing = Uint8List(7 + 8)..fillRange(0, 7, 0xEE);
    final frame = Uint8List.view(backing.buffer, 7, 8)
      ..setAll(0, [10, 20, 30, 255, 40, 50, 60, 255]); // B, G, R, A x2
    final image = imageFromFrameBytes(
      bytes: frame,
      width: 2,
      height: 1,
      bytesPerRow: 8,
      isIOS: true,
      rotationDegrees: 0,
    );

    final first = image.getPixel(0, 0);
    expect([first.r, first.g, first.b], [30, 20, 10]);
    final second = image.getPixel(1, 0);
    expect([second.r, second.g, second.b], [60, 50, 40]);
  });
}
