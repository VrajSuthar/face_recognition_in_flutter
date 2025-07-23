import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:eduwrx/core/constants/app_api.dart';
import 'package:eduwrx/core/services/convert_camera_image_to_img.dart';
import 'package:eduwrx/core/services/face_recognizer.dart';
import 'package:eduwrx/core/utils/common_dialog_box.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/model/search_model.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/model/teacher_model.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/repository/face_recognition_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class FaceRecognitionController extends GetxController {
  /*============================ Variable ============================*/

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
  String? lastRecognizedName;
  DateTime lastRecognitionTime = DateTime.fromMillisecondsSinceEpoch(0);
  final RxSet<int> checkedInUsers = <int>{}.obs;
  final RxSet<int> alreadyCheckOutUsers = <int>{}.obs;
  final RxBool wantToCheckOut = false.obs;
  final Rx<DateTime?> cameraStartTime = Rx<DateTime?>(null);

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

  /*============================ Initialization Function ============================*/

  /// Initializes all necessary components for the app:
  /// - Loads cached or initial data
  /// - Sets up the face detector for live face tracking
  /// - Initializes the face recognizer (e.g., loads models or embeddings)
  /// - Initializes and starts the camera
  /// - Stores the start time of the camera
  /// - Updates loading status to false (UI ready)

  Future<void> initAll() async {
    loadData();
    initializeFaceDetector();
    await initializeFaceRecognizer();
    await initializeCamera();
    cameraStartTime.value = DateTime.now();
    isLoading.value = false;
  }

  void loadData() {
    final arg = Get.arguments;
    if (arg != null) {
      action = arg['action'] ?? '';
    }
  }

  /*============================ Face Preprocessing from Asset  ============================*/

  /// Loads an image from the given asset path and prepares it for face recognition:
  /// - Loads image using the face recognizer's loader
  /// - Saves the image temporarily to be compatible with MLKit's `InputImage`
  /// - Detects the face using MLKit
  /// - Extracts the bounding box of the first detected face
  /// - Crops the face region from the original image
  /// - Resizes the cropped face to 112x112 pixels (standard input size for face models)
  /// - Returns the processed image or null if no face is found

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

  /*============================ Face Preprocessing from Network  ============================*/

  Future<img.Image?> preprocessNetworkFace(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        print("❌ Failed to load image from network: $imageUrl");
        return null;
      }

      final originalImage = img.decodeImage(response.bodyBytes);
      if (originalImage == null) {
        print("❌ Failed to decode image");
        return null;
      }

      // Resize for better face detection
      final resized = img.copyResize(originalImage, width: 480);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_net.jpg')..writeAsBytesSync(img.encodeJpg(resized));

      // Detect face
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) return null;

      final faceBox = faces.first.boundingBox;
      final x = faceBox.left.toInt().clamp(0, resized.width - 1);
      final y = faceBox.top.toInt().clamp(0, resized.height - 1);
      final w = faceBox.width.toInt().clamp(1, resized.width - x);
      final h = faceBox.height.toInt().clamp(1, resized.height - y);

      final cropped = img.copyCrop(resized, x: x, y: y, width: w, height: h);
      return img.copyResize(cropped, width: 112, height: 112);
    } catch (e) {
      print("❌ preprocessNetworkFace error: $e");
      return null;
    }
  }

  /*============================ Face Preprocessing from Local  ============================*/

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

  /*============================ Face Recognizer Initialization ============================*/

  /// Initializes the face recognition system:
  /// - Instantiates the `FaceRecognizer` and loads the recognition model
  /// - Clears any previously known users
  /// - Iterates over the list of students and teachers:
  ///   - Skips entries with missing image URLs
  ///   - Downloads and preprocesses each image from the network
  ///   - Generates an embedding (feature vector) for each valid face
  ///   - Adds the embedding to the `knownUsers` list with the person's name
  /// - Handles errors gracefully and logs failures per user
  /// - Marks the recognizer as ready for use

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

  /*============================ Face Detector Initialization ============================*/

  /// Initializes the MLKit Face Detector with custom options:
  /// - Uses `accurate` performance mode for better detection quality
  /// - Enables detection of facial landmarks (eyes, nose, mouth, etc.)
  /// - Disables contour detection to reduce processing overhead
  /// - Disables classification (e.g., smiling, eyes open) for performance

  void initializeFaceDetector() {
    faceDetector = FaceDetector(options: FaceDetectorOptions(enableContours: false, enableClassification: false, performanceMode: FaceDetectorMode.accurate, enableLandmarks: true));
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false, imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888);

    await cameraController.initialize();
    isCameraInitialized.value = true;

    if (!cameraController.value.isStreamingImages) {
      cameraController.startImageStream((CameraImage image) {
        print("📷 Format group: ${image.format.group}, planes: ${image.planes.length}");
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

  bool get isOneHourPassed {
    final start = cameraStartTime.value;
    if (start == null) return false;
    return DateTime.now().difference(start).inMinutes >= 60;
  }

  Future<void> processCameraImage(CameraImage image) async {
    try {
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

      if (cameraController.description.lensDirection == CameraLensDirection.front) {
        rgbImage = img.flipHorizontal(rgbImage);
      }

      // ✅ Encode to JPEG
      final Uint8List jpegBytes = Uint8List.fromList(img.encodeJpg(rgbImage));

      // ✅ Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/frame.jpg');
      await tempFile.writeAsBytes(jpegBytes);

      // ✅ Load image using fromFile (NOT fromBytes)
      final inputImage = InputImage.fromFile(tempFile);

      // ✅ Detect faces
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

            if (checkedInUsers.contains(refId)) {
              final alreadyCheckedOut = alreadyCheckOutUsers.contains(refId);

              recognizedName.value = matchedName;
              if (!alreadyCheckedOut && action != "check_out") {
                wantToCheckOut.value = true;
              } else {
                wantToCheckOut.value = false;
              }

              if (isCheckIn) {
                faceStatusMessage.value = "⚠️ $matchedName already checked in";
              } else {
                faceStatusMessage.value = alreadyCheckedOut ? "⚠️ $matchedName already checked out" : "✅ $matchedName already check-out";
              }

              print("⚠️ Already checked in (local): $matchedName");
              print("→ wantToCheckOut: ${wantToCheckOut.value}");
              print("→ alreadyCheckedOut: $alreadyCheckedOut");
              print("→ recognizedName: ${recognizedName.value}");

              return;
            }

            // ✅ 2. Call check-in/check-out API
            try {
              if (isCheckIn) {
                await FaceRecognitionRepo.checkIn(teacherId: refId, teacherName: matchedName);
              } else {
                await FaceRecognitionRepo.checkOut(teacherId: refId, teacherName: matchedName);
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

  void willPopFunc(BuildContext context, TextEditingController pinController) async {
    CommonDialogBox.exitFaceRecognitionPopup(
      context,
      pinController: pinController,
      cancelBtn: () {
        Get.back(); // Close dialog only
      },
      onCompleted: (String value) async {
        if (value == "1111") {
          pinController.clear();

          // Step 1: Stop and dispose the camera FIRST
          if (cameraController.value.isStreamingImages) {
            await cameraController.stopImageStream();
          }
          await cameraController.dispose();
          isCameraInitialized.value = false;

          // Step 2: Close the dialog
          if (Get.isDialogOpen ?? false) Get.back(); // Dismiss dialog
          await Future.delayed(Duration(milliseconds: 100));

          // Step 3: Navigate away from screen
          Get.back();
        } else {
          Get.snackbar("Invalid Pin", "Please enter the correct pin to exit.", backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }
}








  // InputImageRotation _rotationIntToImageRotation(int rotation) {
  //   switch (rotation) {
  //     case 0:
  //       return InputImageRotation.rotation0deg;
  //     case 90:
  //       return InputImageRotation.rotation90deg;
  //     case 180:
  //       return InputImageRotation.rotation180deg;
  //     case 270:
  //       return InputImageRotation.rotation270deg;
  //     default:
  //       throw Exception("Invalid sensor rotation: $rotation");
  //   }
  // }
