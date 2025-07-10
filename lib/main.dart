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
import 'package:eduwrx/features/view/on_boarding_view/authentication_view/login/bloc/login_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/bloc/otp_bloc.dart';
import 'package:eduwrx/features/view/on_boarding_view/splash_screen/bloc/splash_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ Wrap in a try-catch to avoid blocking iOS launch
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    requestCameraPermission(),
  ]);

  // Show status and navigation bars with edge-to-edge style
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

  // Apply overlay styling: white background, dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // use transparent for immersive look
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Inject GetX services
  Get.put(ConnectivityService());

  // Run the app
  runApp(const MyApp());
}

Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isGranted) {
    print("✅ Camera permission granted");
  } else if (status.isPermanentlyDenied) {
    print("⚠️ Camera permission permanently denied. Redirecting to settings...");
    // await openAppSettings();
  } else {
    print("❌ Camera permission denied");
  }
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
