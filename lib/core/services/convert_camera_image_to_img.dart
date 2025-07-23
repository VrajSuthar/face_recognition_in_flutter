import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:io'; // for Platform check

Future<img.Image> convertCameraImageToImg(CameraImage image, int sensorOrientation) async {
  final int width = image.width;
  final int height = image.height;

  final img.Image rgbImage = img.Image(width: width, height: height);

  final Uint8List yPlane = image.planes[0].bytes;
  final Uint8List uPlane = image.planes[1].bytes;
  final Uint8List vPlane = image.planes[2].bytes;

  final int yRowStride = image.planes[0].bytesPerRow;
  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int yIndex = y * yRowStride + x;
      final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

      if (yIndex >= yPlane.length || uvIndex >= uPlane.length || uvIndex >= vPlane.length) {
        continue;
      }

      final int yp = yPlane[yIndex];
      final int up = uPlane[uvIndex];
      final int vp = vPlane[uvIndex];

      int r = (yp + 1.370705 * (vp - 128)).round();
      int g = (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128)).round();
      int b = (yp + 1.732446 * (up - 128)).round();

      rgbImage.setPixelRgb(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
    }
  }

  // ✅ Rotate image
  img.Image rotatedImage;
  switch (sensorOrientation) {
    case 90:
      rotatedImage = img.copyRotate(rgbImage, angle: 90);
      break;
    case 180:
      rotatedImage = img.copyRotate(rgbImage, angle: 180);
      break;
    case 270:
      rotatedImage = img.copyRotate(rgbImage, angle: -90);
      break;
    default:
      rotatedImage = rgbImage;
  }

  // ✅ Flip horizontally for front camera (iOS or mirrored Android)
  if (Platform.isIOS || sensorOrientation == 270) {
    rotatedImage = img.flipHorizontal(rotatedImage);
  }

  return rotatedImage;
}

// import 'dart:typed_data';
// import 'dart:io';
// import 'package:camera/camera.dart';
// import 'package:image/image.dart' as img;

// Future<img.Image> convertCameraImageToImg(CameraImage image, int sensorOrientation) async {
//   final int width = image.width;
//   final int height = image.height;

//   late img.Image rgbImage;

//   if (Platform.isIOS && image.planes.length == 1) {
//     // ✅ iOS (bgra8888): bytes are in 4-channel BGRA format
//     final plane = image.planes[0];
//     final bytes = plane.bytes;
//     rgbImage = img.Image(width: width, height: height);

//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         final pixelIndex = (y * width + x) * 4;
//         final b = bytes[pixelIndex];
//         final g = bytes[pixelIndex + 1];
//         final r = bytes[pixelIndex + 2];
//         // final a = bytes[pixelIndex + 3]; // ignored for now

//         rgbImage.setPixelRgb(x, y, r, g, b);
//       }
//     }
//   } else {
//     // ✅ Android (yuv420): handle YUV conversion
//     final Uint8List yPlane = image.planes[0].bytes;
//     final Uint8List uPlane = image.planes[1].bytes;
//     final Uint8List vPlane = image.planes[2].bytes;

//     final int uvRowStride = image.planes[1].bytesPerRow;
//     final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

//     rgbImage = img.Image(width: width, height: height);

//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
//         final int index = y * width + x;

//         final int yp = yPlane[index];
//         final int up = uPlane[uvIndex];
//         final int vp = vPlane[uvIndex];

//         int r = (yp + 1.370705 * (vp - 128)).round();
//         int g = (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128)).round();
//         int b = (yp + 1.732446 * (up - 128)).round();

//         rgbImage.setPixelRgb(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
//       }
//     }
//   }

//   // ✅ Rotate if necessary
//   img.Image rotatedImage;
//   switch (sensorOrientation) {
//     case 90:
//       rotatedImage = img.copyRotate(rgbImage, angle: 90);
//       break;
//     case 180:
//       rotatedImage = img.copyRotate(rgbImage, angle: 180);
//       break;
//     case 270:
//       rotatedImage = img.copyRotate(rgbImage, angle: -90);
//       break;
//     default:
//       rotatedImage = rgbImage;
//   }

//   // ✅ Optionally flip horizontally for iOS front camera
//   if (Platform.isIOS) {
//     rotatedImage = img.flipHorizontal(rotatedImage);
//   }

//   return rotatedImage;
// }
