import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  FaceDetectorService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
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
