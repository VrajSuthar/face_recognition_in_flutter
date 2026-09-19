import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

import 'camera_image_converter.dart';
import 'face_alignment.dart';

typedef _CropArgs = ({
  Uint8List bytes,
  int width,
  int height,
  int bytesPerRow,
  bool isIOS,
  int rotationDegrees,
  double left,
  double top,
  double right,
  double bottom,
  int size,
  List<double>? landmarks,
});

/// Decodes [image] and aligns/crops the face at [box] (in ML Kit's coordinate space,
/// see [imageFromFrameBytes]) down to a [size]×[size] square, on a background
/// isolate so the UI thread never stalls on the pixel work.
Future<img.Image> cropFaceInBackground(
  CameraImage image,
  CameraDescription camera,
  Rect box, {
  required int size,
  required bool isIOS,
  List<double>? landmarks,
}) async {
  final plane = image.planes.first;
  final args = (
    bytes: plane.bytes,
    width: image.width,
    height: image.height,
    bytesPerRow: plane.bytesPerRow,
    isIOS: isIOS,
    rotationDegrees: mlKitRotationDegrees(camera),
    left: box.left,
    top: box.top,
    right: box.right,
    bottom: box.bottom,
    size: size,
    landmarks: landmarks,
  );
  final rgb = await Isolate.run(() => _decodeAndCrop(args));
  return img.Image.fromBytes(
    width: size,
    height: size,
    bytes: rgb.buffer,
    numChannels: 3,
  );
}

Uint8List _decodeAndCrop(_CropArgs a) {
  final frame = imageFromFrameBytes(
    bytes: a.bytes,
    width: a.width,
    height: a.height,
    bytesPerRow: a.bytesPerRow,
    isIOS: a.isIOS,
    rotationDegrees: a.rotationDegrees,
  );
  final cropped = alignFace(
    frame,
    box: Rect.fromLTRB(a.left, a.top, a.right, a.bottom),
    size: a.size,
    landmarks: a.landmarks,
  );
  return cropped.getBytes(order: img.ChannelOrder.rgb);
}
