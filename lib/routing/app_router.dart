import 'package:go_router/go_router.dart';

import '../features/face_recognition/face_recognition_screen.dart';
import '../features/home/home_screen.dart';
import '../features/register_face/register_face_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/face-recognition',
      builder: (context, state) => const FaceRecognitionScreen(),
    ),
    GoRoute(
      path: '/register-face',
      builder: (context, state) => const RegisterFaceScreen(),
    ),
  ],
);
