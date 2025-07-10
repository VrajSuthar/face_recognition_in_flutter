import 'package:face_recognition_demo_1/Home%20screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Face Recognition Demo 1',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      debugShowCheckedModeBanner: false,

      home: HomeScreen(),
    );
  }
}
