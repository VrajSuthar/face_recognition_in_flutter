import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:eduwrx/core/constants/app_image.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/core/utils/common_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            Spacer(),

            SizedBox(width: 16.w),
            IconButton(
              onPressed: () {
                CommonDialogBox.showDialogBox(
                  context,
                  yesBtn: () async {
                    SharedPreferences pref = await SharedPreferences.getInstance();
                    pref.clear();
                    Get.offAllNamed(RouteName.login_screen);
                  },
                  noBtn: () {
                    Get.back();
                  },
                  title: "Sign Out",
                  message: "Are your sure want to sign out",
                );
              },
              icon: Icon(Icons.exit_to_app),
              color: Theme.of(context).iconTheme.color,
              iconSize: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}
