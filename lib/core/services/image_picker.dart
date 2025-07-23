import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;

class ImagePickerHelper {
  final ImagePicker _picker = ImagePicker();

  /// Enable if front camera images need to be flipped (mirrored)
  bool shouldFlipImage = false;

  /// Pick an image from the gallery and optionally crop it
  Future<File?> pickImageFromGallery(BuildContext context) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    return _cropImage(context, File(picked.path));
  }

  /// Pick an image from the camera (front or back) and optionally flip + crop it
  Future<File?> pickImageFromCamera(BuildContext context, {CameraDevice cameraDevice = CameraDevice.front}) async {
    final picked = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: cameraDevice);
    if (picked == null) return null;

    File imageFile = File(picked.path);

    // Flip if front camera and flipping is enabled
    if (cameraDevice == CameraDevice.front && shouldFlipImage) {
      final image = img.decodeImage(await imageFile.readAsBytes());
      if (image != null) {
        final flipped = img.flipHorizontal(image);
        final flippedPath = '${imageFile.parent.path}/flipped_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageFile = await File(flippedPath).writeAsBytes(img.encodeJpg(flipped));
      }
    }

    return _cropImage(context, imageFile);
  }

  /// Crop the image using ImageCropper
  Future<File?> _cropImage(BuildContext context, File file) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          statusBarColor: Theme.of(context).primaryColorDark,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    return cropped != null ? File(cropped.path) : null;
  }
}
