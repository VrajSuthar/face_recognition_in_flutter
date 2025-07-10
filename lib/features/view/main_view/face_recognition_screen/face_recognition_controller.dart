import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:eduwrx/core/services/convert_camera_image_to_img.dart';
import 'package:eduwrx/core/services/face_recognizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

class FaceRecognitionController extends GetxController {
  late CameraController cameraController;
  late FaceRecognizer faceRecognizer;
  late FaceDetector faceDetector;
  final recognizedName = ''.obs;
  RxBool isCameraInitialized = false.obs;
  RxBool isRecognizerReady = false.obs;
  bool isProcessingFrame = false;
  Rect faceOvalRegion = Rect.zero;

  DateTime lastSnackbarTime = DateTime.now().subtract(Duration(seconds: 5));

  List<FaceMatch> knownUsers = [];
  RxString faceStatusMessage = ''.obs;

  final List<UserFace> savedFaces = [
    UserFace(name: "Vraj", imagePath: "assets/png/img1.jpg"),
    UserFace(name: "Krishna", imagePath: "assets/png/img2.jpg"),
    UserFace(name: "Murli", imagePath: "assets/png/img3.jpg"),
  ];

  @override
  void onInit() {
    super.onInit();
    _initAll();
  }

  Future<void> _initAll() async {
    initializeFaceDetector();
    await initializeFaceRecognizer();
    await initializeCamera();
    testSelfMatch(faceRecognizer);
  }

  void testSelfMatch(FaceRecognizer faceRecognizer) async {
    final image = await faceRecognizer.loadAssetImage("assets/png/img1.jpg");
    final emb1 = faceRecognizer.getEmbedding(image);
    final emb2 = faceRecognizer.getEmbedding(image);
    final score = faceRecognizer.compareEmbeddings(emb1, emb2);
    print("🧪 Self-match score: $score"); // should be ~1.0
  }

  Future<img.Image?> preprocessAssetFace(String path) async {
    final image = await faceRecognizer.loadAssetImage(path);

    // Save to file for MLKit
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/detect.jpg')..writeAsBytesSync(img.encodeJpg(image));

    final inputImage = InputImage.fromFilePath(tempFile.path);
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) return null;
    final faceBox = faces.first.boundingBox;

    final x = faceBox.left.toInt().clamp(0, image.width - 1);
    final y = faceBox.top.toInt().clamp(0, image.height - 1);
    final w = faceBox.width.toInt().clamp(1, image.width - x);
    final h = faceBox.height.toInt().clamp(1, image.height - y);

    final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);

    return img.copyResize(cropped, width: 112, height: 112);
  }

  Future<void> initializeFaceRecognizer() async {
    faceRecognizer = FaceRecognizer();
    await faceRecognizer.loadModel();

    knownUsers.clear();
    for (final face in savedFaces) {
      final processed = await preprocessAssetFace(face.imagePath);
      if (processed == null) continue;

      final embedding = faceRecognizer.getEmbedding(processed);
      knownUsers.add(FaceMatch(name: face.name, embedding: embedding));
    }
    print("✅ All saved embeddings loaded");
    isRecognizerReady.value = true;
  }

  void initializeFaceDetector() {
    faceDetector = FaceDetector(options: FaceDetectorOptions(enableContours: false, enableClassification: false, performanceMode: FaceDetectorMode.fast));
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);

    await cameraController.initialize();
    isCameraInitialized.value = true;

    if (!cameraController.value.isStreamingImages) {
      cameraController.startImageStream((CameraImage image) {
        if (!isProcessingFrame && isRecognizerReady.value) {
          isProcessingFrame = true;
          processCameraImage(image);
        }
      });
    }
  }

  bool isFaceInsideOval(Rect faceBox, Rect oval) {
    final faceCenter = faceBox.center;
    final ovalCenter = oval.center;

    final dx = (faceCenter.dx - ovalCenter.dx);
    final dy = (faceCenter.dy - ovalCenter.dy);

    final rx = oval.width / 2;
    final ry = oval.height / 2;

    return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1;
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        throw Exception("Invalid sensor rotation: $rotation");
    }
  }

  Future<void> processCameraImage(CameraImage image) async {
    try {
      // ✅ Validate image format
      if (image.format.group != ImageFormatGroup.yuv420) {
        isProcessingFrame = false;
        return;
      }

      // ✅ Throttle frame processing
      final now = DateTime.now();
      if (now.difference(lastSnackbarTime).inMilliseconds < 700) {
        isProcessingFrame = false;
        return;
      }
      lastSnackbarTime = now;

      // ✅ Convert CameraImage to RGB image
      img.Image rgbImage = await convertCameraImageToImg(image, cameraController.description.sensorOrientation);

      // ✅ Flip for front camera (important for iOS)
      if (cameraController.description.lensDirection == CameraLensDirection.front) {
        rgbImage = img.flipHorizontal(rgbImage);
      }

      // ✅ Save to temporary file
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/temp.jpg';
      final file = File(imagePath)..writeAsBytesSync(img.encodeJpg(rgbImage));
      print("💾 Saved image to $imagePath");

      // ✅ Load image for MLKit
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await faceDetector.processImage(inputImage);
      print("🧠 Faces detected: ${faces.length}");

      if (faces.isEmpty) {
        faceStatusMessage.value = "No face detected";
        print("❌ No face detected");
        return;
      }

      faceStatusMessage.value = "";

      // ✅ Get bounding box
      final faceBox = faces.first.boundingBox;
      final left = faceBox.left.floor().clamp(0, rgbImage.width - 1);
      final top = faceBox.top.floor().clamp(0, rgbImage.height - 1);
      final right = faceBox.right.ceil().clamp(left + 1, rgbImage.width);
      final bottom = faceBox.bottom.ceil().clamp(top + 1, rgbImage.height);
      final width = right - left;
      final height = bottom - top;

      print("📦 Face box: left=$left, top=$top, width=$width, height=$height");

      // ✅ Validate crop size
      if (width <= 0 || height <= 0) {
        print("❌ Invalid crop dimensions: width=$width, height=$height");
        return;
      }

      // ✅ Crop and resize
      final cropped = img.copyCrop(rgbImage, x: left, y: top, width: width, height: height);
      final resized = img.copyResize(cropped, width: 112, height: 112);

      // ✅ Extract embedding
      final currentEmbedding = faceRecognizer.getEmbedding(resized);

      // ✅ Match with known users
      String? matchedName;
      double highestScore = 0.0;

      for (final user in knownUsers) {
        final score = faceRecognizer.compareEmbeddings(currentEmbedding, user.embedding);
        if (score > highestScore && score > 0.65) {
          matchedName = user.name;
          highestScore = score;
        }
      }

      // ✅ Show result
      if (matchedName != null) {
        recognizedName.value = matchedName;
        print("✅ Matched with $matchedName (score: $highestScore)");
      } else {
        print("❌ Face not recognized");
      }
    } catch (e) {
      print("❌ Error in face processing: $e");
    } finally {
      isProcessingFrame = false;
    }
  }

  @override
  void onClose() {
    try {
      if (cameraController.value.isStreamingImages) {
        cameraController.stopImageStream();
      }
      cameraController.dispose();
    } catch (e) {
      print("⚠️ Error during camera cleanup: $e");
    }
    faceDetector.close();
    super.onClose();
  }
}

class UserFace {
  final String name;
  final String imagePath;
  UserFace({required this.name, required this.imagePath});
}
