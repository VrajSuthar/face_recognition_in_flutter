import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_recognition_demo_1/service/convertCameraImageToImg.dart';
import 'package:face_recognition_demo_1/service/face_recognizer.dart';
import 'package:path_provider/path_provider.dart';

class HomeController extends GetxController {
  late CameraController cameraController;
  late FaceRecognizer faceRecognizer;
  late FaceDetector faceDetector;

  RxBool isCameraInitialized = false.obs;
  RxBool isRecognizerReady = false.obs;
  bool isProcessingFrame = false;
  Rect faceOvalRegion = Rect.zero;

  DateTime lastSnackbarTime = DateTime.now().subtract(Duration(seconds: 5));

  List<FaceMatch> knownUsers = [];
  RxString faceStatusMessage = ''.obs;

  final List<UserFace> savedFaces = [
    UserFace(name: "Alice", imagePath: "assets/img1.jpg"),
    UserFace(name: "Alex", imagePath: "assets/img2.jpg"),
    UserFace(name: "Sofiya", imagePath: "assets/img3.jpg"),
    UserFace(name: "Vraj", imagePath: "assets/img4.jpg"),
    UserFace(name: "Krishna", imagePath: "assets/img5.jpg"),
    UserFace(name: "Murli", imagePath: "assets/img6.jpg"),
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
    final image = await faceRecognizer.loadAssetImage("assets/img4.jpg");
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

    final cropped = img.copyCrop(
      image,
      x: faceBox.left.toInt().clamp(0, image.width - 1),
      y: faceBox.top.toInt().clamp(0, image.height - 1),
      width: faceBox.width.toInt().clamp(1, image.width),
      height: faceBox.height.toInt().clamp(1, image.height),
    );

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
    cameraController = cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);

    await cameraController.initialize();
    isCameraInitialized.value = true;

    cameraController.startImageStream((CameraImage image) {
      if (!isProcessingFrame && isRecognizerReady.value) {
        isProcessingFrame = true;
        processCameraImage(image);
      }
    });
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
      if (image.format.group != ImageFormatGroup.yuv420) {
        print("❌ Unsupported format: ${image.format.group}");
        isProcessingFrame = false;
        return;
      }

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final img.Image rgbImage = await convertCameraImageToImg(image, cameraController.description.sensorOrientation);
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/temp.jpg';
      final file = File(imagePath)..writeAsBytesSync(img.encodeJpg(rgbImage));

      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await faceDetector.processImage(inputImage);

      // final List<Face> faces = await faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        faceStatusMessage.value = "No face detected";

        return;
      }

      final Rect faceBox = faces.first.boundingBox;

      if (!isFaceInsideOval(faceBox, faceOvalRegion)) {
        print("🚫 Face is outside oval region");
        return;
      }

      // ✅ 2. Use RGB-converted image for recognition
      final img.Image convertedImage = await convertCameraImageToImg(image, cameraController.description.sensorOrientation);

      final cropped = img.copyCrop(
        convertedImage,
        x: faceBox.left.toInt().clamp(0, convertedImage.width - 1),
        y: faceBox.top.toInt().clamp(0, convertedImage.height - 1),
        width: faceBox.width.toInt().clamp(1, convertedImage.width),
        height: faceBox.height.toInt().clamp(1, convertedImage.height),
      );

      final resized = img.copyResize(cropped, width: 112, height: 112);
      final currentEmbedding = faceRecognizer.getEmbedding(resized);

      String? matchedName;
      double highestScore = 0.0;

      for (final user in knownUsers) {
        final score = faceRecognizer.compareEmbeddings(currentEmbedding, user.embedding);
        if (score > highestScore && score > 0.65) {
          matchedName = user.name;
          highestScore = score;
        }
      }

      if (matchedName != null) {
        _showSnackbar("Face Matched", "Welcome, $matchedName");
      } else {
        print("No Match , Face not recognized");
      }
    } catch (e) {
      print("❌ Error in face processing: $e");
    } finally {
      isProcessingFrame = false;
    }
  }

  void _showSnackbar(String title, String message) {
    final now = DateTime.now();
    if (now.difference(lastSnackbarTime) > Duration(seconds: 3)) {
      Get.snackbar(title, message);
      lastSnackbarTime = now;
    }
  }

  @override
  void onClose() {
    cameraController.dispose();
    faceDetector.close();
    super.onClose();
  }
}

class UserFace {
  final String name;
  final String imagePath;
  UserFace({required this.name, required this.imagePath});
}
