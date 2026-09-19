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
}
