import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../services/face/face_crop.dart';
import '../../services/face/face_entry.dart';
import '../../services/face/providers.dart';

const faceImageSize = 112;

@immutable
class RegisterFaceState {
  const RegisterFaceState({
    this.savedImage,
    this.error,
    this.isProcessing = false,
  });

  final File? savedImage;
  final String? error;
  final bool isProcessing;
}

/// Owns the name field's controller so the screen needs no State object; it is
/// disposed with the screen.
final registerNameControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final registerFaceProvider =
    NotifierProvider.autoDispose<RegisterFaceNotifier, RegisterFaceState>(
      RegisterFaceNotifier.new,
    );

class RegisterFaceNotifier extends Notifier<RegisterFaceState> {
  @override
  RegisterFaceState build() => const RegisterFaceState();

  Future<void> pickAndSave(ImageSource source) async {
    final name = ref.read(registerNameControllerProvider).text.trim();
    if (name.isEmpty) {
      state = const RegisterFaceState(
        error: 'Enter a name before picking an image.',
      );
      return;
    }

    final previous = state.savedImage;
    state = RegisterFaceState(savedImage: previous, isProcessing: true);

    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) {
        if (ref.mounted) state = RegisterFaceState(savedImage: previous);
        return;
      }

      final bytes = await picked.readAsBytes();
      final raw = img.decodeImage(bytes);
      if (raw == null) {
        throw Exception('Could not decode the selected image.');
      }
      // ML Kit's file-based decoder honours EXIF orientation but
      // `img.decodeImage` does not, so bake it in — otherwise the detected
      // bounding box and these pixels disagree for any photo taken in
      // portrait, and the crop grabs the wrong region.
      final decoded = img.bakeOrientation(raw);

      final detector = ref.read(faceDetectorServiceProvider);
      final face = await detector.detectLargestFace(
        InputImage.fromFilePath(picked.path),
      );
      if (face == null) {
        throw Exception('No face detected in the selected image.');
      }

      final cropped = cropFaceSquare(
        decoded,
        face.boundingBox,
        size: faceImageSize,
      );

      final embedder = await ref.read(faceEmbedderServiceProvider.future);
      final embedding = embedder.embed(cropped);

      final repository = await ref.read(faceRepositoryProvider.future);
      if (!await repository.assetsDir.exists()) {
        await repository.assetsDir.create(recursive: true);
      }
      final fileName = 'face_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(p.join(repository.assetsDir.path, fileName));
      await file.writeAsBytes(img.encodePng(cropped));

      await repository.add(
        FaceEntry(name: name, imagePath: file.path, embedding: embedding),
      );

      if (ref.mounted) state = RegisterFaceState(savedImage: file);
    } catch (e) {
      if (ref.mounted) {
        state = RegisterFaceState(
          savedImage: previous,
          error: 'Failed to save image: $e',
        );
      }
    }
  }
}
