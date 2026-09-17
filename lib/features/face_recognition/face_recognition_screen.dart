import 'package:flutter/material.dart';

class FaceRecognitionScreen extends StatelessWidget {
  const FaceRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.face, size: 64), SizedBox(height: 16), Text('Face Recognition')],
        ),
      ),
    );
  }
}
