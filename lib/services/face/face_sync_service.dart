import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'api/face_api_models.dart';
import 'api/face_remote_repository.dart';
import 'face_enrollment.dart';
import 'face_entry.dart';
import 'face_repository.dart';

/// Key in the `sync_state` table holding the server time of the last
/// completed sync.
const lastSyncKey = 'last_sync';

class SyncProgress {
  const SyncProgress({
    required this.peopleDone,
    this.peopleTotal,
    this.currentName,
  });

  final int peopleDone;

  /// Null when the server does not send `totalPeople`.
  final int? peopleTotal;
  final String? currentName;
}

class SyncReport {
  int peopleUpdated = 0;
  int peopleDeleted = 0;
  int photosAdded = 0;
  int photosUnchanged = 0;
  int photosRemoved = 0;

  /// One line per photo that could not be used, e.g.
  /// `Aarav Patel: No face detected in the image.`
  final List<String> problems = [];
}

/// Brings the phone's faces in line with the server.
///
/// Each photo is downloaded into memory, turned into a 112x112 crop and an
/// embedding with the same code the Register Face screen uses, and only those
/// are saved; the downloaded original is never written to storage. Photos
/// whose `sha256` has not changed are skipped, so after the first sync only
/// changes are downloaded.
class FaceSyncService {
  FaceSyncService({
    required this.remote,
    required this.repository,
    required this.enrollPhoto,
  });

  final FaceRemoteRepository remote;
  final FaceRepository repository;

  /// Turns downloaded image bytes into a crop + embedding; in the app this is
  /// [enrollFacePhoto], the same code the Register Face screen uses.
  final Future<EnrolledFace> Function(Uint8List bytes) enrollPhoto;

  Future<SyncReport> sync({void Function(SyncProgress)? onProgress}) async {
    final report = SyncReport();

    // Photos made with an older pipeline can only be redone from the
    // originals, so ask the server for everyone again.
    final fullResync = await repository.hasOutdatedSyncedPhotos();
    final since = fullResync
        ? null
        : await repository.readSyncState(lastSyncKey);

    String? cursor;
    String? syncStartedAt;
    var peopleDone = 0;
    do {
      final page = await remote.fetchSyncPage(since: since, cursor: cursor);
      // The first page's time, not the last one's: anything changed on the
      // server while the later pages were downloading is picked up next time.
      syncStartedAt ??= page.serverTime;

      for (final person in page.people) {
        onProgress?.call(
          SyncProgress(
            peopleDone: peopleDone,
            peopleTotal: page.totalPeople,
            currentName: person.name,
          ),
        );
        await _syncPerson(person, report);
        peopleDone++;
      }
      cursor = page.nextCursor;
    } while (cursor != null);

    onProgress?.call(
      SyncProgress(peopleDone: peopleDone, peopleTotal: peopleDone),
    );
    // Only saved once every page succeeded; a failed sync is simply repeated,
    // and unchanged photos are skipped the second time.
    await repository.writeSyncState(lastSyncKey, syncStartedAt);
    return report;
  }

  Future<void> _syncPerson(RemotePerson person, SyncReport report) async {
    if (person.deleted) {
      await repository.deletePerson(person.id);
      report.peopleDeleted++;
      return;
    }

    await repository.upsertPerson(
      StoredPerson(
        id: person.id,
        type: person.type,
        name: person.name,
        classSection: person.classSection,
        rollNo: person.rollNo,
        updatedAt: person.updatedAt,
      ),
    );
    report.peopleUpdated++;

    final stored = await repository.photosOf(person.id);
    for (final photo in person.photos) {
      final existing = stored[photo.id];
      if (existing != null &&
          photo.sha256 != null &&
          existing.sha256 == photo.sha256 &&
          existing.embeddingVersion == currentEmbeddingVersion &&
          await File(existing.cropPath).exists()) {
        report.photosUnchanged++;
        continue;
      }
      try {
        await _addPhoto(person, photo);
        report.photosAdded++;
      } on FaceEnrollmentException catch (e) {
        report.problems.add('${person.name}: ${e.message}');
        await remote.reportPhotoProblem(photo.id, e.message);
      } on FaceApiException catch (e) {
        // One broken photo link must not stop the whole school's sync.
        report.problems.add('${person.name}: ${e.message}');
      }
    }

    // The server's list is the complete set; anything else was removed.
    final current = {for (final photo in person.photos) photo.id};
    for (final photoId in stored.keys) {
      if (!current.contains(photoId)) {
        await repository.deletePhoto(photoId);
        report.photosRemoved++;
      }
    }
  }

  Future<void> _addPhoto(RemotePerson person, RemotePhoto photo) async {
    // In memory only: the original photo never touches the phone's storage.
    final bytes = await remote.downloadPhoto(photo.url);
    final enrolled = await enrollPhoto(bytes);

    final dir = repository.syncedCropsDir;
    if (!await dir.exists()) await dir.create(recursive: true);
    final safeId = photo.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final crop = File(p.join(dir.path, '$safeId.png'));
    await crop.writeAsBytes(enrolled.png, flush: true);

    await repository.upsertPhoto(
      id: photo.id,
      personId: person.id,
      sha256: photo.sha256,
      cropPath: crop.path,
      embedding: enrolled.embedding,
      updatedAt: photo.updatedAt,
    );
  }
}
