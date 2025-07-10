import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';

class CommonPinInput extends StatelessWidget {
  final int length;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final TextEditingController controller;
  final Color focusedBorderColor;
  final Color errorBorderColor;
  final String? Function(String?)? validator;
  final Function(String)? onCompleted;

  const CommonPinInput({
    super.key,
    this.length = 4,
    this.backgroundColor = Colors.blueGrey,
    this.borderColor = Colors.grey,
    this.textColor = Colors.white,
    this.focusedBorderColor = Colors.blue,
    this.validator,
    this.errorBorderColor = Colors.red,
    this.onCompleted,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(color: Color(0xff000000)),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: focusedBorderColor, width: 2),
        boxShadow: [BoxShadow(color: focusedBorderColor.withValues(alpha: 0.7))],
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: errorBorderColor, width: 2),
        boxShadow: [BoxShadow(color: errorBorderColor.withValues(alpha: 0.5))],
      ),
    );

    return Pinput(
      length: length,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      validator: validator,
      controller: controller,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      showCursor: true,
      errorPinTheme: errorPinTheme,
      animationCurve: Curves.easeInOut,
      animationDuration: Duration(milliseconds: 300),
      onCompleted: onCompleted,
    );
  }
}
