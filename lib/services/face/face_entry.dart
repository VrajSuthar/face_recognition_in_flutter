/// Bumped whenever the way a face is prepared for the embedder changes, so
/// embeddings made the old way (e.g. before landmark alignment) are never
/// compared against ones made the new way.
///
/// 1 = padded bounding-box crop; 2 = landmark-aligned crop.
const currentEmbeddingVersion = 2;

class FaceEntry {
  const FaceEntry({
    required this.name,
    required this.imagePath,
    required this.embedding,
    this.embeddingVersion = currentEmbeddingVersion,
  });

  final String name;
  final String imagePath;
  final List<double> embedding;
  final int embeddingVersion;

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

  Map<String, dynamic> toJson() => {
    'name': name,
    'imagePath': imagePath,
    'embedding': embedding,
    'embeddingVersion': embeddingVersion,
  };
}
