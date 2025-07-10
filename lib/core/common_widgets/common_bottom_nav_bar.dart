import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<String> labels;
  final List<String> selectedIcons;
  final List<String> unselectedIcons;

  const CustomBottomNavBar({super.key, required this.currentIndex, required this.onTap, required this.labels, required this.selectedIcons, required this.unselectedIcons});

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = const Color(0xff6f6f6f);
    final double tabWidth = 1.sw / labels.length;

    return Stack(
      children: [
        // Bottom Bar Background
        Container(
          height: 90.h,
          padding: EdgeInsets.only(bottom: 16.h), // Space below content
          decoration: BoxDecoration(
            color: Color(0xff00111c),
            border: Border(
              top: BorderSide(color: Color(0xffE0F1FB), width: 4.h),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(labels.length, (index) {
              final isSelected = currentIndex == index;

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.translucent,
                child: SizedBox(
                  width: tabWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 8.h),
                      Image.asset(
                        isSelected ? selectedIcons[index] : unselectedIcons[index],
                        height: 36.h,
                        width: 36.h,
                        color: isSelected ? activeColor : inactiveColor,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      SizedBox(height: 6.h),
                      Text(labels[index], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isSelected ? activeColor : inactiveColor)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        // Top Moving Indicator
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          top: 0,
          left: tabWidth * currentIndex + (tabWidth - 48.w) / 2,
          child: Container(
            height: 4.h,
            width: 48.w,
            decoration: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(2.r)),
          ),
        ),
      ],
    );
  }
}
