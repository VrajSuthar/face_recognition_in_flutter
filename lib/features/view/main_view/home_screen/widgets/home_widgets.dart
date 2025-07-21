import 'package:eduwrx/core/common_widgets/common_app_bar_for_main.dart';
import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class HomeWidgets {
  /*============================ App Bar ============================*/

  Widget appBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: CommonAppBarForMain(),
    );
  }

  /*============================ Cards ============================*/

  Widget body(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Get.toNamed(RouteName.face_recognition_screen, arguments: {"action": "check_in"});
            },
            child: commonBox(context, "Attendance"),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () {
              Get.toNamed(RouteName.face_recognition_screen, arguments: {"action": "check_out"});
            },
            child: commonBox(context, "Check Out"),
          ),
        ],
      ),
    );
  }

  Widget commonBox(BuildContext context, String title) {
    return Container(
      height: 150.h,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), color: AppColors.dark_card_color),
      child: Center(
        child: CommonText(title, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }

  FloatingActionButton addPerson(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Theme.of(context).primaryColor,
      onPressed: () {
        Get.toNamed(RouteName.register_person_screen);
      },
      child: SizedBox(
        height: 24.h,
        width: 24.w,
        child: Icon(Icons.group_add_rounded, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}
