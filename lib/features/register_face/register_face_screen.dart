import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'register_face_notifier.dart';

class RegisterFaceScreen extends ConsumerWidget {
  const RegisterFaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerFaceProvider);
    final notifier = ref.read(registerFaceProvider.notifier);
    final savedImage = state.savedImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Register Face')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ref.watch(registerNameControllerProvider),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: savedImage != null
                    ? ClipRRect(
                        key: ValueKey(savedImage.path),
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          savedImage,
                          width: faceImageSize.toDouble(),
                          height: faceImageSize.toDouble(),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1, size: 64),
              ),
              const SizedBox(height: 16),
              if (savedImage != null)
                Text(
                  'Saved to:\n${savedImage.path}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: state.isProcessing
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () =>
                                notifier.pickAndSave(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                notifier.pickAndSave(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
