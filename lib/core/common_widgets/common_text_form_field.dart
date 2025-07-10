
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonTextFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final TextStyle? hintStyle;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function()? onTap;
  final bool readOnly;
  final Color? fillColor;
  final int? maxLine;
  final AutovalidateMode? autovalidateMode;
  final bool filled;

  const CommonTextFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.fillColor,
    this.autovalidateMode,
    this.filled = true,
    this.hintStyle,
    this.maxLine,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      scrollPhysics: NeverScrollableScrollPhysics(),
      scrollPadding: EdgeInsets.all(0),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onTap: onTap,
      textCapitalization: TextCapitalization.sentences,
      style: Theme.of(context).textTheme.bodyMedium,
      readOnly: readOnly,
      maxLines: maxLine,
      validator: validator,
      inputFormatters: inputFormatters,
      autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintStyle: hintStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
        hintText: hintText ,
        filled: filled,
        fillColor: fillColor ?? Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.white , width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      ),
    );
  }
}
