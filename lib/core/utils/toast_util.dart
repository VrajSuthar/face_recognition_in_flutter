import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';

class ToastUtil {
  static void showToast(
    BuildContext context,
    String message, {
    Widget leadingIcon = const Icon(Icons.info, color: Colors.white),
    Color textColor = Colors.white,
    Color backgroundColor = Colors.grey,
    ToastificationType type = ToastificationType.info,
  }) {
    Toastification().show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomLeft,
      autoCloseDuration: const Duration(seconds: 3),
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      primaryColor: Theme.of(context).primaryColor,
      icon: leadingIcon,
      title: Text(
        message,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.always,
      borderRadius: BorderRadius.circular(10.r),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
