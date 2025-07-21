import 'package:eduwrx/core/routes/route_name.dart';
import 'package:eduwrx/features/view/main_view/face_recognition_screen/face_recognition_screen.dart';
import 'package:eduwrx/features/view/main_view/main_screen/main_screen.dart';
import 'package:eduwrx/features/view/main_view/register_new_person/register_person_screen.dart';
import 'package:eduwrx/features/view/on_boarding_view/login/login_screen.dart';
import 'package:eduwrx/features/view/on_boarding_view/otp_screen/otp_screen.dart';
import 'package:eduwrx/features/view/on_boarding_view/splash_screen/splash_screen.dart';
import 'package:get/get.dart';

class Routes {
  static List<GetPage<dynamic>> appRoutes() => [
    GetPage(name: RouteName.splash_screen, page: () => SplashScreen()),
    GetPage(name: RouteName.login_screen, page: () => LoginScreen()),
    GetPage(name: RouteName.main_screen, page: () => MainScreen()),
    GetPage(name: RouteName.otp_verify_screen, page: () => OtpVerifyScreen()),
    GetPage(name: RouteName.face_recognition_screen, page: () => FaceRecognitionScreen()),
    GetPage(name: RouteName.register_person_screen, page: () => RegisterPersonScreen()),
  ];
}
