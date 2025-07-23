import 'dart:developer';

import 'package:eduwrx/core/constants/global_variable.dart';
import 'package:eduwrx/features/view/main_view/check_in_out_screen/bloc/check_in_out_bloc.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/bloc/register_person_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/core/routes/routes.dart';
import 'package:eduwrx/core/services/connectivity_service.dart';
import 'package:eduwrx/core/theme/app_theme.dart';
import 'package:eduwrx/features/view/main_view/main_screen/bloc/main_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/login/bloc/login_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/splash_screen/bloc/splash_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    requestPermissions(),
  ]);

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  Get.put(ConnectivityService());

  printToken();

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  // Camera Permission
  final cameraStatus = await Permission.camera.request();
  if (cameraStatus.isGranted) {
    print("✅ Camera permission granted");
  } else if (cameraStatus.isPermanentlyDenied) {
    print("⚠️ Camera permission permanently denied. Redirecting to settings...");
    // await openAppSettings();
  } else {
    print("❌ Camera permission denied");
  }

  // Location Permission 👈
  final locationStatus = await Permission.locationWhenInUse.request();
  if (locationStatus.isGranted) {
    print("✅ Location permission granted");
  } else if (locationStatus.isPermanentlyDenied) {
    print("⚠️ Location permission permanently denied. Redirecting to settings...");
    // await openAppSettings();
  } else {
    print("❌ Location permission denied");
  }
}

Future<void> printToken() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  var token = pref.getString(GlobalVariable.token_key);
  log("Token ===> Bearer $token");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<SplashBloc>(create: (_) => SplashBloc()),
            BlocProvider<LoginBloc>(create: (_) => LoginBloc()),
            BlocProvider<MainBloc>(create: (_) => MainBloc()),
            BlocProvider<OtpVerifyBloc>(create: (_) => OtpVerifyBloc()),
            BlocProvider<RegisterPersonBloc>(create: (_) => RegisterPersonBloc()),
            BlocProvider<CheckInOutBloc>(create: (_) => CheckInOutBloc()),
          ],
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: GetMaterialApp(
              title: 'Eduwrx',
              debugShowCheckedModeBanner: false,
              initialRoute: RouteName.splash_screen,
              getPages: Routes.appRoutes(),
              theme: AppTheme.darkTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
            ),
          ),
        );
      },
    );
  }
}
