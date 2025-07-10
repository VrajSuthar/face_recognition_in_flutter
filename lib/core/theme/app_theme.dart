// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primary_color,
    iconTheme: IconThemeData(color: AppColors.icon_color),
    cardColor: AppColors.dark_card_color,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(8.r),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(8.r),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8.r),
      ),
    ),
    // dividerColor: AppColors.dividerColorDark,
    // appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark)),
    // floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: AppColors.darkFloatingAction),
    // tabBarTheme: TabBarTheme(indicatorColor: AppColors.darkTabBarSelectedTab, unselectedLabelColor: AppColors.darkTabBarUnselectedTab, labelColor: AppColors.darkTabBarSelectedTab),
    scaffoldBackgroundColor: AppColors.background_color,
    // bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: AppColors.darkBottomNavBar),
    fontFamily: 'Muli',
    textTheme: TextTheme(
      // Display
      displayLarge: TextStyle(color: AppColors.text_color, fontSize: 57.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),
      displayMedium: TextStyle(color: AppColors.text_color, fontSize: 45.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),
      displaySmall: TextStyle(color: AppColors.text_color, fontSize: 36.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),

      // Headline
      headlineLarge: TextStyle(color: AppColors.text_color, fontSize: 32.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),
      headlineMedium: TextStyle(color: AppColors.text_color, fontSize: 28.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),
      headlineSmall: TextStyle(color: AppColors.text_color, fontSize: 24.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),

      // Title
      titleLarge: TextStyle(color: AppColors.text_color, fontSize: 20.sp, fontWeight: FontWeight.w500, fontFamily: 'Muli'),
      titleMedium: TextStyle(color: AppColors.text_color, fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: 'Muli'),
      titleSmall: TextStyle(color: AppColors.text_color, fontSize: 14.sp, fontWeight: FontWeight.w500, fontFamily: 'Muli'),

      // Body
      bodyLarge: TextStyle(color: AppColors.text_color, fontSize: 16.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),
      bodyMedium: TextStyle(color: AppColors.text_color, fontSize: 14.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),
      bodySmall: TextStyle(color: AppColors.text_color, fontSize: 12.sp, fontWeight: FontWeight.w400, fontFamily: 'Muli'),

      // Label
      labelLarge: TextStyle(color: AppColors.text_color, fontSize: 14.sp, fontWeight: FontWeight.w500, fontFamily: 'Muli'),
      labelMedium: TextStyle(color: AppColors.text_color, fontSize: 12.sp, fontWeight: FontWeight.w500, fontFamily: 'Muli'),
      labelSmall: TextStyle(color: AppColors.text_color, fontSize: 10.sp, fontWeight: FontWeight.w500, fontFamily: 'Muli'),
    ),
  );
}

class AppColors {
  static const Color primary_color = Color(0xff0079ff);
  static const Color background_color = Color(0xff06061a);
  static const Color text_color = Color(0xfff9fbfc);
  static const Color icon_color = Color(0xfff9fbfc);
  static const Color dark_card_color = Color(0xFF36373a);
}
