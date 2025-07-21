import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:eduwrx/core/constants/app_api.dart';
import 'package:eduwrx/core/services/convert_camera_image_to_img.dart';
import 'package:eduwrx/core/services/face_recognizer.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/model/search_model.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/model/teacher_model.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/repository/face_recognition_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
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
  RxList<Datum> listOfTeacherAndStudent = <Datum>[].obs;
  RxBool isLoading = false.obs;
  DateTime lastSnackbarTime = DateTime.now().subtract(Duration(seconds: 5));
  List<FaceMatch> knownUsers = [];
  RxString faceStatusMessage = ''.obs;
  final List<Datum> savedFaces = [];
  TeacherModel? teacher_detail;
  String? action;

  Future<void> initAll() async {
    loadData();
    initializeFaceDetector();
    await initializeFaceRecognizer();
    await initializeCamera();
    isLoading.value = false;
  }

  void loadData() {
    final arg = Get.arguments;
    if (arg != null) {
      action = arg['action'] ?? '';
    }
  }

  Future<img.Image?> preprocessAssetFace(String path) async {
    final image = await faceRecognizer.loadFileImage(path);

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

    for (final face in listOfTeacherAndStudent) {
      if (face.image == null || face.image!.isEmpty) continue;

      try {
        final imageUrl = "${AppApi.image_user}${face.image}";
        final processed = await preprocessNetworkFace(imageUrl);
        if (processed == null) continue;

        final embedding = faceRecognizer.getEmbedding(processed);
        knownUsers.add(FaceMatch(name: face.fullName ?? '', embedding: embedding));
      } catch (e) {
        print("❌ Error processing face for ${face.referenceId}: $e");
      }
    }

    print("✅ All saved embeddings loaded from network images");
    isRecognizerReady.value = true;
  }

  Future<img.Image?> preprocessNetworkFace(String imageUrl) async {
    final image = await faceRecognizer.loadNetworkImage(imageUrl);

    // Save to temp file for ML Kit to detect face
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/detect_network.jpg')..writeAsBytesSync(img.encodeJpg(image));

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

  Future<img.Image?> preprocessLocalFace(String filePath) async {
    final image = await faceRecognizer.loadFileImage(filePath);

    // Save temporarily to use with ML Kit
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/detect_local.jpg')..writeAsBytesSync(img.encodeJpg(image));

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

  void initializeFaceDetector() {
    faceDetector = FaceDetector(options: FaceDetectorOptions(enableContours: false, enableClassification: false, performanceMode: FaceDetectorMode.fast));
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420, fps: 120);

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

  String? lastRecognizedName; // Declare this in your controller
  DateTime lastRecognitionTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Future<void> processCameraImage( CameraImage image) async {
  //   try {
  //     if (image.format.group != ImageFormatGroup.yuv420) {
  //       isProcessingFrame = false;
  //       return;
  //     }

  //     final now = DateTime.now();
  //     if (now.difference(lastSnackbarTime).inMilliseconds < 1000) {
  //       isProcessingFrame = false;
  //       return;
  //     }
  //     lastSnackbarTime = now;

  //     // Convert camera image to RGB
  //     img.Image rgbImage = await convertCameraImageToImg(image, cameraController.description.sensorOrientation);

  //     // Flip image horizontally for front camera
  //     if (cameraController.description.lensDirection == CameraLensDirection.front) {
  //       rgbImage = img.flipHorizontal(rgbImage);
  //     }

  //     // Save RGB image as JPEG temporarily for face detection
  //     final directory = await getTemporaryDirectory();
  //     final imagePath = '${directory.path}/temp.jpg';
  //     File(imagePath).writeAsBytesSync(img.encodeJpg(rgbImage));

  //     final inputImage = InputImage.fromFilePath(imagePath);
  //     final faces = await faceDetector.processImage(inputImage);

  //     if (faces.isEmpty) {
  //       faceStatusMessage.value = "No face detected";
  //       recognizedName.value = '';
  //       return;
  //     }

  //     // Extract face bounding box
  //     final faceBox = faces.first.boundingBox;
  //     final left = faceBox.left.floor().clamp(0, rgbImage.width - 1);
  //     final top = faceBox.top.floor().clamp(0, rgbImage.height - 1);
  //     final right = faceBox.right.ceil().clamp(left + 1, rgbImage.width);
  //     final bottom = faceBox.bottom.ceil().clamp(top + 1, rgbImage.height);
  //     final width = right - left;
  //     final height = bottom - top;

  //     if (width <= 0 || height <= 0) {
  //       recognizedName.value = '';
  //       return;
  //     }

  //     // Crop and resize face to model input size
  //     final cropped = img.copyCrop(rgbImage, x: left, y: top, width: width, height: height);
  //     final resized = img.copyResize(cropped, width: 112, height: 112);

  //     // Get face embedding
  //     final currentEmbedding = faceRecognizer.getEmbedding(resized);

  //     // Compare embedding with known users
  //     String? matchedName;
  //     double highestScore = 0.0;

  //     for (final user in knownUsers) {
  //       final score = faceRecognizer.compareEmbeddings(currentEmbedding, user.embedding);
  //       if (score > highestScore && score > 0.65) {
  //         matchedName = user.name;
  //         highestScore = score;
  //       }
  //     }

  //     if (matchedName != null) {
  //       recognizedName.value = matchedName; // ✅ Assign recognized name
  //       faceStatusMessage.value = '';
  //       print("✅ Recognized: $matchedName");
  //     } else {
  //       recognizedName.value = ''; // ❌ No match
  //       faceStatusMessage.value = '';
  //       print("❌ No match found");
  //     }
  //   } catch (e) {
  //     faceStatusMessage.value = '';
  //     recognizedName.value = '';
  //     print("❌ Error in face processing: $e");
  //   } finally {
  //     isProcessingFrame = false;
  //   }
  // }

  final RxSet<int> checkedInUsers = <int>{}.obs;

  Future<void> processCameraImage(CameraImage image) async {
    try {
      if (image.format.group != ImageFormatGroup.yuv420) {
        isProcessingFrame = false;
        return;
      }

      final now = DateTime.now();
      if (now.difference(lastSnackbarTime).inMilliseconds < 1000) {
        isProcessingFrame = false;
        return;
      }
      lastSnackbarTime = now;

      img.Image rgbImage = await convertCameraImageToImg(image, cameraController.description.sensorOrientation);

      if (cameraController.description.lensDirection == CameraLensDirection.front) {
        rgbImage = img.flipHorizontal(rgbImage);
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/frame.jpg';
      File(tempPath).writeAsBytesSync(img.encodeJpg(rgbImage));

      final inputImage = InputImage.fromFilePath(tempPath);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) faceStatusMessage.value = '';
      if (faces.isEmpty) {
        faceStatusMessage.value = "No face detected";
        recognizedName.value = '';
        return;
      }

      bool faceRecognized = false;

      for (final face in faces) {
        final box = face.boundingBox;
        final left = box.left.floor().clamp(0, rgbImage.width - 1);
        final top = box.top.floor().clamp(0, rgbImage.height - 1);
        final right = box.right.ceil().clamp(left + 1, rgbImage.width);
        final bottom = box.bottom.ceil().clamp(top + 1, rgbImage.height);
        final width = right - left;
        final height = bottom - top;

        if (width <= 0 || height <= 0) continue;

        final faceCenterX = box.center.dx;
        final faceCenterY = box.center.dy;
        final overlayWidth = rgbImage.width.toDouble();
        final overlayHeight = rgbImage.height.toDouble();
        final ovalCenterX = overlayWidth / 2;
        final ovalCenterY = overlayHeight / 2;
        final ovalRadiusX = overlayWidth * 0.35;
        final ovalRadiusY = overlayHeight * 0.35;

        final dx = (faceCenterX - ovalCenterX) / ovalRadiusX;
        final dy = (faceCenterY - ovalCenterY) / ovalRadiusY;

        if ((dx * dx + dy * dy) > 1.0) {
          faceStatusMessage.value = "Put your face inside the oval";
          recognizedName.value = '';
          return;
        }

        final cropped = img.copyCrop(rgbImage, x: left, y: top, width: width, height: height);
        final resized = img.copyResize(cropped, width: 112, height: 112);
        final embedding = faceRecognizer.getEmbedding(resized);

        String? matchedName;
        double highestScore = 0.0;

        for (final user in knownUsers) {
          final score = faceRecognizer.compareEmbeddings(embedding, user.embedding);
          print("📏 Cosine similarity with ${user.name}: $score");

          if (score > highestScore && score > 0.65) {
            matchedName = user.name;
            highestScore = score;
          }
        }

        if (matchedName != null) {
          final matchedUser = listOfTeacherAndStudent.firstWhereOrNull((u) => u.fullName == matchedName);
          if (matchedUser != null) {
            final int refId = matchedUser.referenceId ?? 0;
            final bool isCheckIn = action == "check_in";

            recognizedName.value = matchedName;
            faceStatusMessage.value = "✅ $matchedName recognized";

            // ✅ 1. Local duplicate validation
            if (checkedInUsers.contains(refId)) {
              isCheckIn ? faceStatusMessage.value = "⚠️ $matchedName already checked in" : faceStatusMessage.value = "⚠️ $matchedName already checked out";
              print("⚠️ Already checked in (local): $matchedName");
              return; // ⬅️ Stop further processing
            }

            // ✅ 2. Call check-in/check-out API
            try {
              if (isCheckIn) {
                await FaceRecognitionRepo.checkIn(teacherId: refId, locationCheckIn: "Auto face check-in", teacherName: matchedName);
              } else {
                await FaceRecognitionRepo.checkOut(teacherId: refId, locationCheckIn: "Auto face check-out", teacherName: matchedName);
              }

              checkedInUsers.add(refId);
              faceStatusMessage.value = isCheckIn ? "✅ Checked in: $matchedName" : "✅ Checked out: $matchedName";
              print("✅ ${isCheckIn ? "Checked in" : "Checked out"}: $matchedName");
            } catch (e) {
              final errorMessage = e.toString();

              if (errorMessage.contains("already checked in")) {
                faceStatusMessage.value = "⚠️ $matchedName already checked in (server)";
                checkedInUsers.add(refId); // prevent repeated API call
                showDialog(
                  context: Get.context!,
                  builder: (_) => AlertDialog(
                    title: const Text("Already Checked In"),
                    content: Text("$matchedName has already checked in today."),
                    actions: [TextButton(onPressed: () => Get.back(), child: const Text("OK"))],
                  ),
                );
              } else {
                faceStatusMessage.value = "❌ Failed to check-in $matchedName";
                print("❌ API error for $matchedName: $e");
              }
            }

            faceRecognized = true;
          }
        }
      }

      if (!faceRecognized) {
        faceStatusMessage.value = "Face not recognized";
        recognizedName.value = '';
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
