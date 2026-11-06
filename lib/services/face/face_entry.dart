/// Bumped whenever the way a face is prepared for the embedder changes, so
/// embeddings made the old way (e.g. before landmark alignment) are never
/// compared against ones made the new way.
///
/// 1 = padded bounding-box crop; 2 = landmark-aligned crop.
const currentEmbeddingVersion = 2;

/// The person id given to someone registered on this phone (not from the
/// server). Registering the same name again adds photos to the same person,
/// as it always has.
String localPersonId(String name) => 'local:${name.trim().toLowerCase()}';

/// One stored photo of one person.
class FaceEntry {
  const FaceEntry({
    required this.name,
    required this.imagePath,
    required this.embedding,
    this.embeddingVersion = currentEmbeddingVersion,
    this.personId,
  });

  final String name;
  final String imagePath;
  final List<double> embedding;
  final int embeddingVersion;

  /// The server's id for synced people (e.g. `stu_1024`), or the
  /// [localPersonId] of someone registered on this phone. Null only before a
  /// locally registered entry is saved.
  final String? personId;

  /// What matching groups photos by: two different people can share a name,
  /// but never an id.
  String get personKey => personId ?? localPersonId(name);

  /// Reads the legacy `faces_index.json` format, only used to migrate it.
  factory FaceEntry.fromJson(Map<String, dynamic> json) {
    return FaceEntry(
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      embedding: (json['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      embeddingVersion: (json['embeddingVersion'] as num?)?.toInt() ?? 1,
    );
  }
}
