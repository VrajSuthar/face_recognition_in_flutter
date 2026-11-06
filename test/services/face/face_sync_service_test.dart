import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:face_recognition_app_1/services/face/api/face_api_config.dart';
import 'package:face_recognition_app_1/services/face/api/face_remote_repository.dart';
import 'package:face_recognition_app_1/services/face/face_enrollment.dart';
import 'package:face_recognition_app_1/services/face/face_repository.dart';
import 'package:face_recognition_app_1/services/face/face_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _person(
  String id,
  List<Map<String, dynamic>> photos, {
  bool deleted = false,
}) => {
  'id': id,
  'type': 'student',
  'name': 'Person $id',
  'deleted': deleted,
  'photos': photos,
};

Map<String, dynamic> _photo(String id, String sha) => {
  'id': id,
  'url': 'https://api.test/photos/$id.jpg',
  'sha256': sha,
};

void main() {
  late Directory dir;
  late FaceRepository repository;
  late List<Map<String, dynamic>> pages;
  late List<Uri> requests;
  late Set<String> noFacePhotos;

  FaceSyncService service() {
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.path == '/api/faces/sync') {
        final cursor = request.url.queryParameters['cursor'];
        final index = cursor == null ? 0 : int.parse(cursor);
        return http.Response(jsonEncode(pages[index]), 200);
      }
      if (request.url.path == '/api/faces/photo-status') {
        return http.Response('{}', 200);
      }
      return http.Response.bytes(utf8.encode(request.url.path), 200);
    });
    return FaceSyncService(
      remote: FaceRemoteRepository(
        const FaceApiConfig(baseUrl: 'https://api.test'),
        client: client,
      ),
      repository: repository,
      enrollPhoto: (bytes) async {
        final path = utf8.decode(bytes);
        if (noFacePhotos.any(path.contains)) {
          throw const FaceEnrollmentException('No face detected in the image.');
        }
        return EnrolledFace(
          png: Uint8List.fromList([1, 2, 3]),
          embedding: [path.length.toDouble(), 1],
        );
      },
    );
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_test');
    repository = FaceRepository(dir);
    requests = [];
    noFacePhotos = {};
  });

  tearDown(() async {
    await repository.close();
    await dir.delete(recursive: true);
  });

  test('first sync downloads every page and stores each photo', () async {
    pages = [
      {
        'serverTime': 'T1',
        'nextCursor': '1',
        'people': [
          _person('stu_1', [_photo('p1', 'a'), _photo('p2', 'b')]),
        ],
      },
      {
        'serverTime': 'T1-later',
        'people': [
          _person('tch_1', [_photo('p3', 'c')]),
        ],
      },
    ];

    final report = await service().sync();

    expect(report.photosAdded, 3);
    final stored = await repository.loadAll();
    expect(stored.map((e) => e.personKey), ['stu_1', 'stu_1', 'tch_1']);
    expect(stored.every((e) => File(e.imagePath).existsSync()), isTrue);
    // The first page's time, so changes made mid-sync are not missed.
    expect(await repository.readSyncState(lastSyncKey), 'T1');
  });

  test('next sync sends since, skips unchanged photos and removes deleted ones',
      () async {
    pages = [
      {
        'serverTime': 'T1',
        'people': [
          _person('stu_1', [_photo('p1', 'a'), _photo('p2', 'b')]),
          _person('stu_2', [_photo('p3', 'c')]),
        ],
      },
    ];
    await service().sync();
    requests.clear();

    pages = [
      {
        'serverTime': 'T2',
        'people': [
          // p2 removed on the server, p1 unchanged.
          _person('stu_1', [_photo('p1', 'a')]),
          _person('stu_2', [], deleted: true),
        ],
      },
    ];
    final report = await service().sync();

    expect(requests.first.queryParameters['since'], 'T1');
    expect(requests.where((u) => u.path.startsWith('/photos/')), isEmpty);
    expect(report.photosUnchanged, 1);
    expect(report.photosRemoved, 1);
    expect(report.peopleDeleted, 1);
    final stored = await repository.loadAll();
    expect(stored.single.personKey, 'stu_1');
  });

  test('a photo with no face is reported, not fatal', () async {
    noFacePhotos = {'p2'};
    pages = [
      {
        'serverTime': 'T1',
        'people': [
          _person('stu_1', [_photo('p1', 'a'), _photo('p2', 'b')]),
        ],
      },
    ];

    final report = await service().sync();

    expect(report.photosAdded, 1);
    expect(report.problems.single, contains('No face detected'));
    expect(
      requests.where((u) => u.path == '/api/faces/photo-status'),
      hasLength(1),
    );
  });

  test('a failed page leaves last_sync unchanged so the sync is retried',
      () async {
    pages = [
      {'serverTime': 'T1', 'nextCursor': '1', 'people': []},
    ];

    await expectLater(service().sync(), throwsA(anything));
    expect(await repository.readSyncState(lastSyncKey), isNull);
  });
}
