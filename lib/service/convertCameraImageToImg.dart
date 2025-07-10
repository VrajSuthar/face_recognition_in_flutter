import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'dart:typed_data';

Future<img.Image> convertCameraImageToImg(CameraImage image, int sensorOrientation) async {
  final int width = image.width;
  final int height = image.height;

  final img.Image rgbImage = img.Image(width: width, height: height);

  final Uint8List yPlane = image.planes[0].bytes;
  final Uint8List uPlane = image.planes[1].bytes;
  final Uint8List vPlane = image.planes[2].bytes;

  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
      final int index = y * width + x;

      final int yp = yPlane[index];
      final int up = uPlane[uvIndex];
      final int vp = vPlane[uvIndex];

      int r = (yp + 1.370705 * (vp - 128)).round();
      int g = (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128)).round();
      int b = (yp + 1.732446 * (up - 128)).round();

      rgbImage.setPixelRgb(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
    }
  }

  // ✅ Rotate image based on the camera orientation
  switch (sensorOrientation) {
    case 90:
      return img.copyRotate(rgbImage, angle: 90);
    case 180:
      return img.copyRotate(rgbImage, angle: 180);
    case 270:
      return img.copyRotate(rgbImage, angle: -90);
    default:
      return rgbImage;
  }
}
