import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _faceImageSize = 112;

class RegisterFaceScreen extends StatefulWidget {
  const RegisterFaceScreen({super.key});

  @override
  State<RegisterFaceScreen> createState() => _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  File? _savedImage;
  String? _error;
  bool _isProcessing = false;

  Future<void> _pickAndSaveImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Could not decode the selected image.');
      }

      final resized = img.copyResizeCropSquare(
        decoded,
        size: _faceImageSize,
      );

      final documentsDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory(p.join(documentsDir.path, 'assets'));
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      final fileName =
          'face_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(p.join(assetsDir.path, fileName));
      await file.writeAsBytes(img.encodePng(resized));

      setState(() {
        _savedImage = file;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to save image: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Face')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_savedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _savedImage!,
                    width: _faceImageSize.toDouble(),
                    height: _faceImageSize.toDouble(),
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Icon(Icons.person_add_alt_1, size: 64),
              const SizedBox(height: 16),
              if (_savedImage != null)
                Text(
                  'Saved to:\n${_savedImage!.path}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 24),
              if (_isProcessing)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickAndSaveImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _pickAndSaveImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
