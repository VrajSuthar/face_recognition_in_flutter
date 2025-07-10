import 'package:eduwrx/features/view/main_view/home_screen/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeWidgets homeWidgets = HomeWidgets();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                homeWidgets.appBar(),
                SizedBox(height: 16.h),
                homeWidgets.body(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
