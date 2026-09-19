import 'package:face_recognition_app_1/features/register_face/register_face_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('asks for a name before picking an image', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterFaceScreen())),
    );

    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name before picking an image.'), findsOneWidget);
  });
}
