import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'face_alignment.dart';
import 'face_detector_service.dart';
import 'face_embedder_service.dart';

/// Side of the aligned face crop that is stored and embedded.
const faceImageSize = 112;

/// Photos are shrunk to this longest side before detection. A 12 MP photo
/// gains nothing for a 112x112 crop and would only slow every step down.
const _maxPhotoSide = 1280;

/// A photo turned into what the app stores: the aligned crop and its
/// embedding.
class EnrolledFace {
  const EnrolledFace({required this.png, required this.embedding});

  final Uint8List png;
  final List<double> embedding;
}

/// Why a photo could not be enrolled; [toString] is the plain message, ready
/// to show to the user.
class FaceEnrollmentException implements Exception {
  const FaceEnrollmentException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns an encoded photo (JPEG, PNG, …) into an [EnrolledFace]. Shared by the
/// Register Face screen and the server sync, so both store embeddings made
/// exactly the same way.
///
/// Decoding, resizing and aligning run on background isolates; only detection
/// and the TFLite model run on the calling isolate.
Future<EnrolledFace> enrollFacePhoto(
  Uint8List encoded, {
  required FaceDetectorService detector,
  required FaceEmbedderService embedder,
  required Directory tempDir,
}) async {
  final prepared = await Isolate.run(() => _decodeUpright(encoded));
  if (prepared == null) {
    throw const FaceEnrollmentException('Could not decode the image.');
  }
  final (upright, jpg) = prepared;

  // Detect on the *baked* pixels via a temp file rather than on the original
  // file. iOS front-camera captures can carry a mirrored EXIF orientation that
  // ML Kit's own iOS file loader doesn't always resolve the same way `image`'s
  // bakeOrientation does, which silently fails detection on iOS. Detecting on
  // the same upright pixels used for the crop also guarantees they can never
  // disagree.
  final tempFile = File(
    p.join(tempDir.path, 'enroll_${DateTime.now().microsecondsSinceEpoch}.jpg'),
  );
  await tempFile.writeAsBytes(jpg, flush: true);
  final Face? face;
  try {
    face = await detector.detectLargestFace(
      InputImage.fromFilePath(tempFile.path),
    );
  } finally {
    if (await tempFile.exists()) await tempFile.delete();
  }
  if (face == null) {
    throw const FaceEnrollmentException('No face detected in the image.');
  }

  final box = face.boundingBox;
  final landmarks = face.alignmentLandmarks;
  final (aligned, png) = await Isolate.run(() {
    final aligned = alignFace(
      upright,
      box: box,
      size: faceImageSize,
      landmarks: landmarks,
    );
    return (aligned, Uint8List.fromList(img.encodePng(aligned)));
  });

  return EnrolledFace(png: png, embedding: embedder.embed(aligned));
}

/// Decodes, applies EXIF orientation (`img.decodeImage` ignores it, so the
/// detected box and the pixels would disagree for portrait photos), shrinks,
/// and re-encodes as JPEG for the detector.
(img.Image, Uint8List)? _decodeUpright(Uint8List encoded) {
  final raw = img.decodeImage(encoded);
  if (raw == null) return null;
  var upright = img.bakeOrientation(raw);
  final longest = max(upright.width, upright.height);
  if (longest > _maxPhotoSide) {
    final scale = _maxPhotoSide / longest;
    upright = img.copyResize(
      upright,
      width: (upright.width * scale).round(),
      height: (upright.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }
  return (upright, Uint8List.fromList(img.encodeJpg(upright, quality: 95)));
}
