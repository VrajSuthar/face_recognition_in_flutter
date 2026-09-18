import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Builds an ML Kit [InputImage] from a raw camera frame. Requires the
/// [CameraController] to have been created with
/// `imageFormatGroup: ImageFormatGroup.bgra8888` on iOS or
/// `ImageFormatGroup.nv21` on Android — both formats hand back a single
/// image plane, which is what this function assumes.
InputImage? inputImageFromCameraImage(
  CameraImage image,
  CameraDescription camera,
) {
  final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;
  if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
  if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
  if (image.planes.length != 1) return null;

  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}

/// Decodes a raw camera frame into a [img.Image] in the *same,
/// un-rotated* pixel coordinate space that ML Kit's [Face.boundingBox]
/// is reported in, so a box from [inputImageFromCameraImage]'s result can
/// be used directly against this image (e.g. via `cropFaceSquare`).
img.Image imageFromCameraImage(CameraImage image) {
  return Platform.isIOS ? _bgra8888ToImage(image) : _nv21ToImage(image);
}

img.Image _bgra8888ToImage(CameraImage image) {
  final plane = image.planes.first;
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: plane.bytes.buffer,
    order: img.ChannelOrder.bgra,
    rowStride: plane.bytesPerRow,
  );
}

img.Image _nv21ToImage(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final bytes = image.planes.first.bytes;
  final frameSize = width * height;
  final out = img.Image(width: width, height: height);

  for (var row = 0; row < height; row++) {
    for (var col = 0; col < width; col++) {
      final y = bytes[row * width + col] & 0xff;
      final uvRow = row ~/ 2;
      final uvCol = col ~/ 2;
      final uvIndex = frameSize + uvRow * width + uvCol * 2;
      final v = bytes[uvIndex] & 0xff;
      final u = bytes[uvIndex + 1] & 0xff;

      final r = (y + 1.370705 * (v - 128)).round().clamp(0, 255);
      final g =
          (y - 0.337633 * (u - 128) - 0.698001 * (v - 128)).round().clamp(0, 255);
      final b = (y + 1.732446 * (u - 128)).round().clamp(0, 255);

      out.setPixelRgb(col, row, r, g, b);
    }
  }
  return out;
}
