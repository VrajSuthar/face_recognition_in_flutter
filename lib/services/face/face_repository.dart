import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'face_entry.dart';

/// A person as stored on the phone, whether synced from the server or
/// registered locally.
class StoredPerson {
  const StoredPerson({
    required this.id,
    required this.type,
    required this.name,
    this.classSection,
    this.rollNo,
    this.updatedAt,
  });

  final String id;

  /// `teacher`, `student`, or `local` for people registered on this phone.
  final String type;
  final String name;
  final String? classSection;
  final String? rollNo;
  final String? updatedAt;
}

/// What the phone already has for one server photo, so sync can skip photos
/// that have not changed.
class StoredPhotoInfo {
  const StoredPhotoInfo({
    required this.sha256,
    required this.embeddingVersion,
    required this.cropPath,
  });

  final String? sha256;
  final int embeddingVersion;
  final String cropPath;
}

/// Faces and people in a SQLite database (`faces.db`) inside [assetsDir].
///
/// Embeddings are stored as a binary BLOB of float64 values, and every change
/// touches only its own rows, so saving a photo stays fast however many
/// people are registered.
class FaceRepository {
  FaceRepository(this.assetsDir);

  final Directory assetsDir;

  static Future<FaceRepository> forAppDocuments() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return FaceRepository(Directory(p.join(documentsDir.path, 'assets')));
  }

  /// Where crops of synced photos live, one `<photoId>.png` per photo.
  Directory get syncedCropsDir => Directory(p.join(assetsDir.path, 'synced'));

  File get _legacyIndexFile =>
      File(p.join(assetsDir.path, 'faces_index.json'));

  Future<Database>? _db;
  Future<Database> get _database => _db ??= _open();

  Future<Database> _open() async {
    if (!await assetsDir.exists()) await assetsDir.create(recursive: true);
    final db = await openDatabase(
      p.join(assetsDir.path, 'faces.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE people (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            class_section TEXT,
            roll_no TEXT,
            updated_at TEXT
          )''');
        await db.execute('''
          CREATE TABLE face_photos (
            id TEXT PRIMARY KEY,
            person_id TEXT NOT NULL REFERENCES people(id) ON DELETE CASCADE,
            sha256 TEXT,
            crop_path TEXT NOT NULL,
            embedding BLOB NOT NULL,
            embedding_version INTEGER NOT NULL,
            updated_at TEXT
          )''');
        await db.execute(
          'CREATE INDEX face_photos_person ON face_photos(person_id)',
        );
        await db.execute(
          'CREATE TABLE sync_state (key TEXT PRIMARY KEY, value TEXT)',
        );
      },
    );
    await _migrateLegacyIndex(db);
    return db;
  }

  /// Imports faces saved by older versions of the app (`faces_index.json`)
  /// once, then renames the file so it is never imported twice.
  Future<void> _migrateLegacyIndex(Database db) async {
    final legacy = _legacyIndexFile;
    if (!await legacy.exists()) return;
    final contents = await legacy.readAsString();
    if (contents.trim().isNotEmpty) {
      final list = jsonDecode(contents) as List;
      final entries = list
          .map((e) => FaceEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      await db.transaction((txn) async {
        for (final entry in entries) {
          await _insertLocal(txn, entry);
        }
      });
    }
    await legacy.rename('${legacy.path}.migrated');
  }

  /// Every stored photo with its person's name, ready for matching.
  Future<List<FaceEntry>> loadAll() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT f.person_id, f.crop_path, f.embedding, f.embedding_version,
             p.name
      FROM face_photos f JOIN people p ON p.id = f.person_id
      ORDER BY f.rowid''');
    return [
      for (final row in rows)
        FaceEntry(
          name: row['name'] as String,
          imagePath: row['crop_path'] as String,
          embedding: _decodeEmbedding(row['embedding'] as Uint8List),
          embeddingVersion: row['embedding_version'] as int,
          personId: row['person_id'] as String,
        ),
    ];
  }

  /// Saves a photo registered on this phone (the Register Face screen).
  Future<void> add(FaceEntry entry) async {
    final db = await _database;
    await db.transaction((txn) => _insertLocal(txn, entry));
  }

  static var _localPhotoCounter = 0;

  Future<void> _insertLocal(DatabaseExecutor db, FaceEntry entry) async {
    final personId = entry.personKey;
    await db.insert('people', {
      'id': personId,
      'type': 'local',
      'name': entry.name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('face_photos', {
      'id':
          'local_${DateTime.now().microsecondsSinceEpoch}_'
          '${_localPhotoCounter++}',
      'person_id': personId,
      'crop_path': entry.imagePath,
      'embedding': _encodeEmbedding(entry.embedding),
      'embedding_version': entry.embeddingVersion,
    });
  }

  // ---- Used by FaceSyncService ----

  Future<void> upsertPerson(StoredPerson person) async {
    final db = await _database;
    // Not `ConflictAlgorithm.replace`: SQLite's REPLACE deletes the old row
    // first, and the ON DELETE CASCADE would take all their photos with it.
    await db.rawInsert(
      '''INSERT INTO people (id, type, name, class_section, roll_no, updated_at)
         VALUES (?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           type = excluded.type,
           name = excluded.name,
           class_section = excluded.class_section,
           roll_no = excluded.roll_no,
           updated_at = excluded.updated_at''',
      [
        person.id,
        person.type,
        person.name,
        person.classSection,
        person.rollNo,
        person.updatedAt,
      ],
    );
  }

  /// The photos already stored for [personId], keyed by photo id.
  Future<Map<String, StoredPhotoInfo>> photosOf(String personId) async {
    final db = await _database;
    final rows = await db.query(
      'face_photos',
      columns: ['id', 'sha256', 'embedding_version', 'crop_path'],
      where: 'person_id = ?',
      whereArgs: [personId],
    );
    return {
      for (final row in rows)
        row['id'] as String: StoredPhotoInfo(
          sha256: row['sha256'] as String?,
          embeddingVersion: row['embedding_version'] as int,
          cropPath: row['crop_path'] as String,
        ),
    };
  }

  Future<void> upsertPhoto({
    required String id,
    required String personId,
    required String? sha256,
    required String cropPath,
    required List<double> embedding,
    String? updatedAt,
  }) async {
    final db = await _database;
    await db.insert('face_photos', {
      'id': id,
      'person_id': personId,
      'sha256': sha256,
      'crop_path': cropPath,
      'embedding': _encodeEmbedding(embedding),
      'embedding_version': currentEmbeddingVersion,
      'updated_at': updatedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Removes one photo row and its crop file.
  Future<void> deletePhoto(String photoId) async {
    final db = await _database;
    final rows = await db.query(
      'face_photos',
      columns: ['crop_path'],
      where: 'id = ?',
      whereArgs: [photoId],
    );
    await db.delete('face_photos', where: 'id = ?', whereArgs: [photoId]);
    for (final row in rows) {
      await _deleteFile(row['crop_path'] as String);
    }
  }

  /// Removes a person, all their photo rows, and all their crop files.
  Future<void> deletePerson(String personId) async {
    final photos = await photosOf(personId);
    final db = await _database;
    await db.delete('people', where: 'id = ?', whereArgs: [personId]);
    for (final photo in photos.values) {
      await _deleteFile(photo.cropPath);
    }
  }

  /// True when a synced photo was embedded with an older pipeline and has to
  /// be downloaded and processed again.
  Future<bool> hasOutdatedSyncedPhotos() async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''SELECT 1 FROM face_photos f JOIN people p ON p.id = f.person_id
         WHERE p.type != 'local' AND f.embedding_version != ? LIMIT 1''',
      [currentEmbeddingVersion],
    );
    return rows.isNotEmpty;
  }

  Future<String?> readSyncState(String key) async {
    final db = await _database;
    final rows = await db.query(
      'sync_state',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> writeSyncState(String key, String? value) async {
    final db = await _database;
    await db.insert('sync_state', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await (await db).close();
  }

  static Uint8List _encodeEmbedding(List<double> embedding) =>
      Float64List.fromList(embedding).buffer.asUint8List();

  static List<double> _decodeEmbedding(Uint8List bytes) {
    // Copy into an aligned buffer: a BLOB can start at any byte offset.
    final aligned = Uint8List.fromList(bytes);
    return Float64List.view(aligned.buffer).toList();
  }

  static Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
