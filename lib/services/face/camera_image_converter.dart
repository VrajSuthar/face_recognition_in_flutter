import 'dart:io';
import 'dart:typed_data';
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
  final rotation = InputImageRotationValue.fromRawValue(
    mlKitRotationDegrees(camera),
  );
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

/// The clockwise rotation, in degrees, handed to ML Kit for [camera].
///
/// This is the single source of truth shared by [inputImageFromCameraImage]
/// (which puts it in the [InputImageMetadata]) and [imageFromCameraImage]
/// (which applies it to the decoded pixels on Android), so the two can never
/// drift apart.
///
/// v1 assumes the device is held in portrait — `FaceRecognitionScreen` locks
/// the orientation while it is active. A rotation-aware version would combine
/// `sensorOrientation` with the live device orientation per lens direction
/// (see the google_mlkit_commons README).
int mlKitRotationDegrees(CameraDescription camera) =>
    camera.sensorOrientation % 360;

/// Decodes a raw camera frame into an [img.Image] that lives in the *same*
/// pixel coordinate space ML Kit reports [Face.boundingBox] in, so a box from
/// the detector can be used directly against this image (e.g. via
/// `cropFaceSquare`).
///
/// On Android, google_mlkit_commons hands the raw buffer to
/// `InputImage.fromByteArray(..., rotationDegrees, ...)`; ML Kit rotates the
/// image clockwise by that many degrees and reports detections in the
/// *rotated* space. So the decoded pixels have to be rotated by the very same
/// clockwise angle here — `img.copyRotate` rotates clockwise for a positive
/// angle — otherwise the crop is taken from the wrong region entirely.
///
/// On iOS, google_mlkit_commons ignores the `rotation` metadata, so ML Kit's
/// boxes stay in the raw BGRA buffer's space and no rotation must be applied.
///
/// Takes plain values (no [CameraImage]) so it can run in a background
/// isolate — the per-pixel NV21 conversion is far too slow for the UI thread.
img.Image imageFromFrameBytes({
  required Uint8List bytes,
  required int width,
  required int height,
  required int bytesPerRow,
  required bool isIOS,
  required int rotationDegrees,
}) {
  if (isIOS) {
    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.bgra,
      rowStride: bytesPerRow,
    );
  }

  final decoded = _nv21ToImage(bytes, width, height);
  if (rotationDegrees == 0) return decoded;
  return img.copyRotate(decoded, angle: rotationDegrees);
}

/// NV21 -> RGB with integer math straight into a byte buffer. The per-pixel
/// `setPixelRgb` + floating point version this replaced was the slowest step
/// in the recognition pipeline.
img.Image _nv21ToImage(Uint8List bytes, int width, int height) {
  final frameSize = width * height;
  final rgb = Uint8List(frameSize * 3);
  var out = 0;
  for (var row = 0; row < height; row++) {
    final yRow = row * width;
    final uvRow = frameSize + (row >> 1) * width;
    for (var col = 0; col < width; col++) {
      final y = bytes[yRow + col];
      final uvIndex = uvRow + (col & ~1);
      final v = bytes[uvIndex] - 128;
      final u = bytes[uvIndex + 1] - 128;

      final r = y + ((1404 * v) >> 10);
      final g = y - ((346 * u + 715 * v) >> 10);
      final b = y + ((1774 * u) >> 10);

      rgb[out++] = r < 0 ? 0 : (r > 255 ? 255 : r);
      rgb[out++] = g < 0 ? 0 : (g > 255 ? 255 : g);
      rgb[out++] = b < 0 ? 0 : (b > 255 ? 255 : b);
    }
  }
  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgb.buffer,
    numChannels: 3,
  );
}
