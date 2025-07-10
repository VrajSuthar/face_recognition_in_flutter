import 'package:eduwrx/core/constants/app_image.dart';
import 'package:eduwrx/features/view/on_boarding_view/splash_screen/bloc/splash_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/splash_screen/bloc/splash_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:member_ogr/core/constants/app_images.dart';
// import 'package:member_ogr/features/views/on_boarding/splash_screen/bloc/splash_bloc.dart';
// import 'package:member_ogr/features/views/on_boarding/splash_screen/bloc/splash_event.dart';
// import 'package:member_ogr/features/views/on_boarding/splash_screen/bloc/splash_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  /*============================ Variable ============================*/

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /*============================ Variable ============================*/

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
    context.read<SplashBloc>().add(StartSplashTimer());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 1.sh,
            width: 1.sw,
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Container(height: 1.sh, width: 1.sw, color: Colors.black.withOpacity(0.7)),
          Positioned(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(AppImages.login_logo, fit: BoxFit.fill),
            ),
          ),
          // Positioned(bottom: 0, left: 0, right: 0, child: Image.asset(AppImages.branding, height: 0.1.sh)),
        ],
      ),
    );
  }
}
