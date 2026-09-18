import 'dart:io';

import 'package:face_recognition_app_1/services/face/face_entry.dart';
import 'package:face_recognition_app_1/services/face/face_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late FaceRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('face_repo_test');
    repository = FaceRepository(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loadAll returns an empty list when no index file exists', () async {
    expect(await repository.loadAll(), isEmpty);
  });

  test('add persists an entry that loadAll returns', () async {
    const entry = FaceEntry(
      name: 'Alice',
      imagePath: '/tmp/alice.png',
      embedding: [0.1, 0.2, 0.3],
    );

    await repository.add(entry);
    final loaded = await repository.loadAll();

    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Alice');
    expect(loaded.first.embedding, [0.1, 0.2, 0.3]);
  });

  test('add appends to existing entries in order', () async {
    await repository.add(
      const FaceEntry(name: 'Alice', imagePath: 'a', embedding: [1]),
    );
    await repository.add(
      const FaceEntry(name: 'Bob', imagePath: 'b', embedding: [2]),
    );

    final loaded = await repository.loadAll();
    expect(loaded.map((e) => e.name), ['Alice', 'Bob']);
  });
}
