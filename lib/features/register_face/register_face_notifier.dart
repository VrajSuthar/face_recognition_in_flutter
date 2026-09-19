import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../services/face/face_alignment.dart';
import '../../services/face/face_detector_service.dart';
import '../../services/face/face_entry.dart';
import '../../services/face/providers.dart';

const faceImageSize = 112;

/// A photo that has been detected, aligned and embedded but not yet stored.
@immutable
class PendingFace {
  const PendingFace({required this.png, required this.embedding});

  final Uint8List png;
  final List<double> embedding;
}

@immutable
class RegisterFaceState {
  const RegisterFaceState({
    this.pending = const [],
    this.saved = const [],
    this.confirmation,
    this.error,
    this.isProcessing = false,
    this.isSaving = false,
  });

  /// Photos waiting for the user to press Save.
  final List<PendingFace> pending;

  /// Files from the last save, each confirmed to exist on disk.
  final List<File> saved;

  /// Human-readable proof of the last successful save.
  final String? confirmation;
  final String? error;
  final bool isProcessing;
  final bool isSaving;

  bool get isBusy => isProcessing || isSaving;

  RegisterFaceState copyWith({
    List<PendingFace>? pending,
    List<File>? saved,
    String? confirmation,
    bool clearConfirmation = false,
    String? error,
    bool clearError = false,
    bool? isProcessing,
    bool? isSaving,
  }) {
    return RegisterFaceState(
      pending: pending ?? this.pending,
      saved: saved ?? this.saved,
      confirmation: clearConfirmation
          ? null
          : (confirmation ?? this.confirmation),
      error: clearError ? null : (error ?? this.error),
      isProcessing: isProcessing ?? this.isProcessing,
      isSaving: isSaving ?? this.isSaving,
    );
  }
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

  String get _name => ref.read(registerNameControllerProvider).text.trim();

  /// Picks photos, prepares each one, and queues them for saving. Nothing is
  /// written to disk until [save].
  Future<void> addPhotos(ImageSource source) async {
    if (_name.isEmpty) {
      state = state.copyWith(error: 'Enter a name before picking an image.');
      return;
    }

    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearConfirmation: true,
    );

    try {
      final picker = ImagePicker();
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await picker.pickMultiImage();
      } else {
        final one = await picker.pickImage(source: source);
        picked = one == null ? const [] : [one];
      }

      final added = <PendingFace>[];
      final failures = <String>[];
      for (final file in picked) {
        try {
          added.add(await _prepare(file));
        } catch (e) {
          failures.add(
            '${p.basename(file.path)}: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }

      if (!ref.mounted) return;
      state = state.copyWith(
        pending: [...state.pending, ...added],
        isProcessing: false,
        error: failures.isEmpty
            ? null
            : 'Skipped ${failures.length} photo(s) — ${failures.join('; ')}',
        clearError: failures.isEmpty,
      );
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isProcessing: false,
          error: 'Could not add photo: $e',
        );
      }
    }
  }

  void removePending(int index) {
    if (index < 0 || index >= state.pending.length) return;
    final next = [...state.pending]..removeAt(index);
    state = state.copyWith(pending: next, clearError: true);
  }

  /// Queues an already-prepared photo. Used by [addPhotos]; exposed so the
  /// save path can be tested without a camera or picker.
  void addPending(PendingFace face) {
    state = state.copyWith(
      pending: [...state.pending, face],
      clearConfirmation: true,
    );
  }

  /// Writes every pending photo and its embedding, then reads everything back
  /// to confirm each one really was stored before reporting success.
  Future<void> save() async {
    final name = _name;
    if (name.isEmpty) {
      state = state.copyWith(error: 'Enter a name before saving.');
      return;
    }
    final toSave = state.pending;
    if (toSave.isEmpty || state.isBusy) return;

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearConfirmation: true,
    );

    try {
      final repository = await ref.read(faceRepositoryProvider.future);
      if (!await repository.assetsDir.exists()) {
        await repository.assetsDir.create(recursive: true);
      }

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final written = <(File, Uint8List)>[];
      for (var i = 0; i < toSave.length; i++) {
        final file = File(
          p.join(repository.assetsDir.path, 'face_${stamp}_$i.png'),
        );
        await file.writeAsBytes(toSave[i].png, flush: true);
        await repository.add(
          FaceEntry(
            name: name,
            imagePath: file.path,
            embedding: toSave[i].embedding,
          ),
        );
        written.add((file, toSave[i].png));
      }

      // Read back from disk rather than trusting the writes above.
      final stored = await repository.loadAll();
      final verified = <File>[];
      for (final (file, png) in written) {
        final indexed = stored.any(
          (e) => e.imagePath == file.path && e.name == name,
        );
        final onDisk = await file.exists() && await file.length() == png.length;
        if (indexed && onDisk) verified.add(file);
      }
      final total = stored.where((e) => e.name == name).length;

      if (!ref.mounted) return;
      if (verified.length == toSave.length) {
        state = RegisterFaceState(
          saved: verified,
          confirmation:
              'Saved ${verified.length} photo'
              '${verified.length == 1 ? '' : 's'} for $name and verified on '
              'disk. $name now has $total registered photo'
              '${total == 1 ? '' : 's'}.',
        );
      } else {
        state = state.copyWith(
          saved: verified,
          isSaving: false,
          error:
              'Only ${verified.length} of ${toSave.length} photos could be '
              'verified on disk. Please try saving again.',
        );
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(isSaving: false, error: 'Failed to save: $e');
      }
    }
  }

  Future<PendingFace> _prepare(XFile picked) async {
    final raw = img.decodeImage(await picked.readAsBytes());
    if (raw == null) {
      throw Exception('Could not decode the selected image.');
    }
    // ML Kit's file-based decoder honours EXIF orientation but
    // `img.decodeImage` does not, so bake it in — otherwise the detected
    // bounding box and these pixels disagree for any photo taken in
    // portrait, and the crop grabs the wrong region.
    final decoded = img.bakeOrientation(raw);

    final face = await ref
        .read(enrollmentDetectorServiceProvider)
        .detectLargestFace(InputImage.fromFilePath(picked.path));
    if (face == null) {
      throw Exception('No face detected in the selected image.');
    }

    final aligned = alignFace(
      decoded,
      box: face.boundingBox,
      size: faceImageSize,
      landmarks: face.alignmentLandmarks,
    );

    final embedder = await ref.read(faceEmbedderServiceProvider.future);
    return PendingFace(
      png: Uint8List.fromList(img.encodePng(aligned)),
      embedding: embedder.embed(aligned),
    );
  }
}
