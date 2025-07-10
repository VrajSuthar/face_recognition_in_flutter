import 'package:camera/camera.dart';
import 'package:face_recognition_demo_1/Home%20screen/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = Get.put(HomeController());

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
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // ✅ Camera Preview
            SizedBox.expand(child: CameraPreview(controller.cameraController)),

            // ✅ Dimmed background with oval cutout (drawn underneath the border)
            IgnorePointer(
              child: Center(
                child: CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: HolePainter(ovalWidth: ovalWidth, ovalHeight: ovalHeight),
                ),
              ),
            ),

            // ✅ Oval border on top (moved below)
            Center(
              child: Container(
                width: ovalWidth,
                height: ovalHeight,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.all(Radius.elliptical(ovalWidth, ovalHeight)),
                ),
              ),
            ),

            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Obx(() {
                final message = controller.faceStatusMessage.value;
                if (message.isEmpty) return SizedBox.shrink();
                return Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                    child: Text(message, style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}

/// ✅ Painter to dim area outside the oval
class HolePainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;

  HolePainter({required this.ovalWidth, required this.ovalHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Path fullScreenPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path ovalPath = Path()..addOval(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: ovalWidth, height: ovalHeight));

    final Path finalPath = Path.combine(PathOperation.difference, fullScreenPath, ovalPath);
    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
