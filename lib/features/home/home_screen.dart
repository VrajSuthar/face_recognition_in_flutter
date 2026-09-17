import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home, size: 64),
            const SizedBox(height: 16),
            const Text('Home'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/face-recognition'),
              child: const Text('Face Recognition'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/register-face'),
        tooltip: 'Register Face',
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}
