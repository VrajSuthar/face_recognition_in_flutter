import 'dart:convert';
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

  test('imports an old faces_index.json once and renames it', () async {
    final legacy = File('${tempDir.path}/faces_index.json');
    await legacy.writeAsString(
      jsonEncode([
        {'name': 'Ann', 'imagePath': 'a.png', 'embedding': [1, 2], 'embeddingVersion': 2},
      ]),
    );

    final loaded = await repository.loadAll();

    expect(loaded.single.name, 'Ann');
    expect(loaded.single.embedding, [1, 2]);
    expect(await legacy.exists(), isFalse);
    expect(await File('${legacy.path}.migrated').exists(), isTrue);
    expect(await FaceRepository(tempDir).loadAll(), hasLength(1));
  });

  test('updating a synced person keeps their photos', () async {
    const person = StoredPerson(id: 'stu_1', type: 'student', name: 'Aarav');
    await repository.upsertPerson(person);
    await repository.upsertPhoto(
      id: 'ph_1',
      personId: 'stu_1',
      sha256: 'abc',
      cropPath: 'x.png',
      embedding: [0.5, 0.25],
    );

    await repository.upsertPerson(
      const StoredPerson(id: 'stu_1', type: 'student', name: 'Aarav P.'),
    );

    final loaded = await repository.loadAll();
    expect(loaded.single.name, 'Aarav P.');
    expect(loaded.single.personId, 'stu_1');
  });

  test('deletePerson removes their photos and crop files', () async {
    final crop = File('${tempDir.path}/crop.png')..writeAsBytesSync([1]);
    await repository.upsertPerson(
      const StoredPerson(id: 'stu_1', type: 'student', name: 'Aarav'),
    );
    await repository.upsertPhoto(
      id: 'ph_1',
      personId: 'stu_1',
      sha256: null,
      cropPath: crop.path,
      embedding: [1],
    );

    await repository.deletePerson('stu_1');

    expect(await repository.loadAll(), isEmpty);
    expect(await crop.exists(), isFalse);
  });

  test('two synced people with the same name stay separate', () async {
    for (final id in ['stu_1', 'stu_2']) {
      await repository.upsertPerson(
        StoredPerson(id: id, type: 'student', name: 'Aarav Patel'),
      );
      await repository.upsertPhoto(
        id: 'ph_$id',
        personId: id,
        sha256: null,
        cropPath: '$id.png',
        embedding: [1],
      );
    }

    final keys = (await repository.loadAll()).map((e) => e.personKey);
    expect(keys, ['stu_1', 'stu_2']);
  });
}
