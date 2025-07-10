import 'package:eduwrx/core/common_widgets/common_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Commonbtn extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final double width;
  final double height;
  final bool isLoading;
  final double borderRadius;
  final Color textColor;
  final double fontSize;
  final BorderRadius? border;
  final FontWeight fontWeight;
  final Color borderColor;
  final double borderWidth;
  final bool hasShadow;
  final List<BoxShadow>? customShadow;

  const Commonbtn({
    super.key,
    required this.text,
    this.onTap,
    this.color = const Color(0xff0079ff),
    this.width = double.infinity,
    this.height = 50,
    this.borderRadius = 10,
    this.textColor = Colors.white,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.hasShadow = true,
    this.customShadow,
    this.border,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCircular = isLoading;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap ?? () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isCircular ? 50.w : (width.isFinite ? width.w : MediaQuery.of(context).size.width),
        height: height.h,
        decoration: BoxDecoration(
          borderRadius: isCircular ? BorderRadius.circular(100.r) : border ?? BorderRadius.circular(borderRadius.r),
          color: color,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: hasShadow ? customShadow ?? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, spreadRadius: 1, offset: const Offset(0, 4))] : [],
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: width.w,
          height: height.h,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('loader'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : SizedBox(
                      key: const ValueKey('text'),
                      width: width.w,
                      child: Center(
                        child: CommonText(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: fontSize, fontWeight: fontWeight, color: textColor),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
