import 'package:camera/camera.dart';
import 'package:eduwrx/core/common_widgets/common_button.dart';
import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:eduwrx/core/common_widgets/oval_painter.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/face_recognition_controller.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/repository/face_recognition_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class FaceRecognitionScreen extends StatefulWidget {
  FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> with TickerProviderStateMixin {
  final FaceRecognitionController controller = Get.put(FaceRecognitionController());
  late final AnimationController _lottieController;
  TextEditingController pinController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this);

    FaceRecognitionRepo().fetchFaceSearch(context);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double ovalWidth = 300;
    const double ovalHeight = 400;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final ovalRect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: ovalWidth, height: ovalHeight);
      controller.faceOvalRegion = ovalRect;
    });

    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          controller.willPopFunc(context, pinController);
          return false;
        },
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: SizedBox(
                width: 220.w.clamp(150.0, 280.0),
                height: 220.h.clamp(150.0, 280.0),
                child: Lottie.asset(
                  'assets/lotti_json/loading.json',
                  controller: _lottieController,
                  onLoaded: (composition) {
                    _lottieController
                      ..duration = composition.duration
                      ..repeat();
                  },
                  fit: BoxFit.fill,
                ),
              ),
            );
          }

          return Stack(
            children: [
              Obx(() {
                return controller.isCameraInitialized.value ? SizedBox.expand(child: CameraPreview(controller.cameraController)) : const Center(child: CircularProgressIndicator());
              }),

              // ✅ Oval Overlay
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: OvalPainter(controller.faceOvalRegion))),
              ),

              // 🔁 Face status message
              controller.faceStatusMessage.value == ''
                  ? const SizedBox.shrink()
                  : Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Obx(() {
                        final message = controller.faceStatusMessage.value;
                        if (message.isEmpty) return const SizedBox.shrink();
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                            child: CommonText(message, style: Theme.of(context).textTheme.bodySmall),
                          ),
                        );
                      }),
                    ),

              // ✅ Recognized name (bottom sheet UI)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Obx(() {
                  final recognizedName = controller.recognizedName.value;
                  final hasMatch = recognizedName.isNotEmpty;
                  final action = controller.action;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: hasMatch
                          ? action == "check_out"
                                ? Colors.blue
                                : Colors.green
                          : Colors.black87,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        CommonText(hasMatch ? recognizedName : "Recognizing...", style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  );
                }),
              ),

              // ✅ Conditionally render the Check Out button
              Positioned(
                left: 0,
                right: 0,
                bottom: 150,
                child: Obx(() {
                  final recognizedName = controller.recognizedName.value;
                  final matchedUser = controller.listOfTeacherAndStudent.firstWhereOrNull((u) => u.fullName == recognizedName);
                  final refId = matchedUser?.referenceId ?? 0;

                  final shouldShowCheckout =
                      recognizedName.isNotEmpty &&
                      controller.wantToCheckOut.value &&
                      controller.checkedInUsers.contains(refId) &&
                      !controller.alreadyCheckOutUsers.contains(refId) &&
                      controller.action != 'check_out';

                  if (!shouldShowCheckout) return const SizedBox.shrink();

                  return Center(
                    child: Column(
                      children: [
                        CommonText("Do you wish to check out?", style: Theme.of(context).textTheme.bodyLarge),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: () async {
                            try {
                              await FaceRecognitionRepo.checkOut(teacherId: refId, teacherName: recognizedName);
                              controller.alreadyCheckOutUsers.add(refId);
                              controller.faceStatusMessage.value = "✅ Checked out: $recognizedName";
                            } catch (e) {
                              controller.faceStatusMessage.value = "❌ Failed to check-out: $recognizedName";
                            }
                          },
                          child: Container(
                            width: 0.5.sw,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
                            ),
                            child: const Center(
                              child: CommonText(
                                "Check Out",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              // Optional: Icon Button
              Positioned(
                top: 64,
                right: 16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Get.toNamed(RouteName.register_person_screen);
                  },
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.group_add_rounded, size: 24, color: Colors.black),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
