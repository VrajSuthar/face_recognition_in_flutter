import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'face_entry.dart';

class FaceRepository {
  FaceRepository(this.assetsDir);

  final Directory assetsDir;

  static Future<FaceRepository> forAppDocuments() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return FaceRepository(Directory(p.join(documentsDir.path, 'assets')));
  }

  File get _indexFile => File(p.join(assetsDir.path, 'faces_index.json'));

  Future<List<FaceEntry>> loadAll() async {
    if (!await _indexFile.exists()) return [];
    final contents = await _indexFile.readAsString();
    if (contents.trim().isEmpty) return [];
    final list = jsonDecode(contents) as List;
    return list
        .map((e) => FaceEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(FaceEntry entry) async {
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    final entries = await loadAll();
    entries.add(entry);
    await _indexFile.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
