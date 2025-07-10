import 'package:camera/camera.dart';
import 'package:eduwrx/core/common_widgets/oval_painter.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/face_recognition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FaceRecognitionScreen extends StatelessWidget {
  FaceRecognitionScreen({super.key});

  final FaceRecognitionController controller = Get.put(FaceRecognitionController());

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
          await controller.cameraController.stopImageStream();
          await controller.cameraController.dispose();
          return true;
        },
        child: Obx(() {
          if (!controller.isCameraInitialized.value || !controller.cameraController.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              // ✅ Camera Preview
              SizedBox.expand(child: CameraPreview(controller.cameraController)),



              // ✅ Oval Overlay (face alignment guide)
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: OvalPainter(controller.faceOvalRegion))),
              ),

              // 🔁 Face status message
              controller.faceStatusMessage.value == ''
                  ? SizedBox.shrink()
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
                            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 16)),
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
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          recognizedName.isNotEmpty ? recognizedName : "Recognizing...",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
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
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.group_add_rounded, size: 32, color: Colors.black),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
