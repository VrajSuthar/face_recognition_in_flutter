import 'dart:ui';

import 'package:eduwrx/core/common_widgets/common_button.dart';
import 'package:eduwrx/core/common_widgets/common_pin_input.dart';
import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:eduwrx/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CommonDialogBox {
  static void showDialogBox(BuildContext context, {VoidCallback? yesBtn, VoidCallback? noBtn, String title = "", String message = ""}) {
    final bgColor = Theme.of(context).cardColor;
    final boxShadow = [BoxShadow(color: Colors.black12, spreadRadius: 4, blurRadius: 12, offset: Offset(0, 4))];

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        titlePadding: EdgeInsets.only(bottom: 24, top: 16, left: 16, right: 16),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Column(
          children: [
            CommonText(title, style: Theme.of(context).textTheme.bodyLarge),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CommonText(message, style: Theme.of(context).textTheme.bodyMedium, maxLines: 3),
              ),
          ],
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Commonbtn(
                height: 0.05.sh,
                text: "No",
                onTap: noBtn,
                borderColor: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: bgColor,
                textColor: Colors.white,
                customShadow: boxShadow,
              ),
            ),
            SizedBox(width: 16.w),
            Flexible(
              child: Commonbtn(
                height: 0.05.sh,
                text: "Yes",
                onTap: yesBtn,
                borderColor: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: bgColor,
                textColor: Colors.white,
                customShadow: boxShadow,
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

static void exitFaceRecognitionPopup(
    BuildContext context, {
    required TextEditingController pinController,
    VoidCallback? cancelBtn,
    String message = "",
    void Function(String)? onCompleted, // ✅ Accepts a String
  }) {
    final bgColor = Theme.of(context).cardColor;
    final boxShadow = [BoxShadow(color: Colors.black12, spreadRadius: 4, blurRadius: 12, offset: Offset(0, 4))];

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: EdgeInsets.only(bottom: 0, top: 16, left: 16, right: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonText("Exit", style: Theme.of(context).textTheme.bodyLarge),
            if (message.isNotEmpty) ...[SizedBox(height: 8.h), CommonText(message, style: Theme.of(context).textTheme.bodyMedium, maxLines: 3, textAlign: TextAlign.center)],
            SizedBox(height: 16.h),
            CommonPinInput(
              length: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Pin is required";
                }
                return null;
              },
              controller: pinController,
              backgroundColor: Colors.white,
              borderColor: Colors.grey,
              textColor: Colors.black,
              focusedBorderColor: Theme.of(context).primaryColor,
              onCompleted: onCompleted,
            ),
            SizedBox(height: 24.h),
            Commonbtn(
              height: 0.05.sh,
              text: "Cancel",
              onTap: cancelBtn,
              borderColor: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: bgColor,
              textColor: Colors.white,
              customShadow: boxShadow,
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

}
