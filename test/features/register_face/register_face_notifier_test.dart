import 'dart:io';
import 'dart:typed_data';

import 'package:face_recognition_app_1/features/register_face/register_face_notifier.dart';
import 'package:face_recognition_app_1/services/face/face_repository.dart';
import 'package:face_recognition_app_1/services/face/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

PendingFace _face(double seed) {
  final image = img.Image(width: 8, height: 8);
  img.fill(image, color: img.ColorRgb8(seed.round(), 10, 10));
  return PendingFace(
    png: Uint8List.fromList(img.encodePng(image)),
    embedding: [seed, 1, 2],
  );
}

void main() {
  late Directory dir;
  late ProviderContainer container;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('register_test');
    container = ProviderContainer(
      overrides: [
        faceRepositoryProvider.overrideWith((ref) => FaceRepository(dir)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await dir.delete(recursive: true);
    });
    container.listen(registerFaceProvider, (_, _) {});
    container.listen(registerNameControllerProvider, (_, _) {});
  });

  test(
    'save writes every pending photo, verifies them, and clears the queue',
    () async {
      container.read(registerNameControllerProvider).text = 'Ann';
      final notifier = container.read(registerFaceProvider.notifier);
      notifier.addPending(_face(10));
      notifier.addPending(_face(20));

      await notifier.save();

      final state = container.read(registerFaceProvider);
      expect(state.error, isNull);
      expect(state.pending, isEmpty);
      expect(state.saved, hasLength(2));
      expect(state.saved.every((f) => f.existsSync()), isTrue);
      expect(state.confirmation, contains('Saved 2 photos for Ann'));
      expect(state.confirmation, contains('now has 2'));

      final stored = await FaceRepository(dir).loadAll();
      expect(stored.map((e) => e.name), ['Ann', 'Ann']);
      expect(stored.map((e) => e.embedding.first), [10, 20]);
    },
  );

  test('save without a name stores nothing and explains why', () async {
    final notifier = container.read(registerFaceProvider.notifier);
    notifier.addPending(_face(10));

    await notifier.save();

    final state = container.read(registerFaceProvider);
    expect(state.error, 'Enter a name before saving.');
    expect(state.pending, hasLength(1));
    expect(await FaceRepository(dir).loadAll(), isEmpty);
  });

  test('removePending drops just that photo', () {
    final notifier = container.read(registerFaceProvider.notifier);
    notifier.addPending(_face(10));
    notifier.addPending(_face(20));

    notifier.removePending(0);

    final pending = container.read(registerFaceProvider).pending;
    expect(pending, hasLength(1));
    expect(pending.single.embedding.first, 20);
  });
}
