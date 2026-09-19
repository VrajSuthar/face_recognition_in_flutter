import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  /// [FaceDetectorMode.fast] for the live camera; [FaceDetectorMode.accurate]
  /// for one-off registration photos, where landmark quality matters more than
  /// speed.
  FaceDetectorService({FaceDetectorMode mode = FaceDetectorMode.fast})
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: mode,
          enableLandmarks: true,
        ),
      );

  final FaceDetector _detector;

  Future<Face?> detectLargestFace(InputImage image) async {
    final faces = await _detector.processImage(image);
    if (faces.isEmpty) return null;

    var largest = faces.first;
    var largestArea = largest.boundingBox.width * largest.boundingBox.height;
    for (final face in faces.skip(1)) {
      final area = face.boundingBox.width * face.boundingBox.height;
      if (area > largestArea) {
        largest = face;
        largestArea = area;
      }
    }
    return largest;
  }

  void close() => _detector.close();
}

extension FaceAlignmentLandmarks on Face {
  /// `[eyeX, eyeY, eyeX, eyeY, mouthX, mouthY, mouthX, mouthY]` in the same
  /// coordinate space as [Face.boundingBox], or null if any landmark is
  /// missing. Consumed by `alignFace`.
  List<double>? get alignmentLandmarks {
    final points = [
      landmarks[FaceLandmarkType.leftEye]?.position,
      landmarks[FaceLandmarkType.rightEye]?.position,
      landmarks[FaceLandmarkType.leftMouth]?.position,
      landmarks[FaceLandmarkType.rightMouth]?.position,
    ];
    if (points.any((p) => p == null)) return null;
    return [
      for (final p in points) ...[p!.x.toDouble(), p.y.toDouble()],
    ];
  }
}
