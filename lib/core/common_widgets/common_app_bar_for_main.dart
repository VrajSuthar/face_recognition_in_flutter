import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:eduwrx/core/constants/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class CommonAppBarForMain extends StatelessWidget {
  CommonAppBarForMain({super.key});

  // NotificationController notificationController = Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: 1.sw,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 40.h,
              width: 40.w,
              child: Image.asset(AppImages.mainLogo, fit: BoxFit.fill),
            ),

            SizedBox(width: 8.w),
            CommonText("Eduwrx", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            // Spacer(),
            // GestureDetector(
            //   onTap: () {
            //     // Get.toNamed(RouteName.notificationScreen);
            //   },
            //   child: SizedBox(
            //     height: 24.h,
            //     width: 24.w,
            //     child: Stack(
            //       children: [
            //         Image.asset(AppImages.bell, color: Theme.of(context).iconTheme.color),

            //         // notificationController.notificationList.isEmpty
            //         //     ? SizedBox.shrink()
            //         //     : Positioned(
            //         //         top: 0,
            //         //         right: 0,
            //         //         child: Container(
            //         //           height: 16.h,
            //         //           width: 16.w,
            //         //           decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
            //         //           alignment: Alignment.center,
            //         //           child: customText(notificationController.notificationList.length.toString(), color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            //         //         ),
            //         //       ),
            //       ],
            //     ),
            //   ),
            // ),
            // SizedBox(width: 16.w),
            // GestureDetector(
            //   onTap: () {
            //     // Get.toNamed(RouteName.notificationScreen);
            //   },
            //   child: SizedBox(
            //     height: 24.h,
            //     width: 24.w,
            //     child: Stack(
            //       children: [
            //         Image.asset(AppImages.profile_icon, color: Theme.of(context).iconTheme.color, fit: BoxFit.fill),
            //         // notificationController.notificationList.isEmpty
            //         //     ? SizedBox.shrink()
            //         //     : Positioned(
            //         //         top: 0,
            //         //         right: 0,
            //         //         child: Container(
            //         //           height: 16.h,
            //         //           width: 16.w,
            //         //           decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
            //         //           alignment: Alignment.center,
            //         //           child: customText(notificationController.notificationList.length.toString(), color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            //         //         ),
            //         //       ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
