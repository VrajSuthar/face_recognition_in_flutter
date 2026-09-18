class FaceEntry {
  const FaceEntry({
    required this.name,
    required this.imagePath,
    required this.embedding,
  });

  final String name;
  final String imagePath;
  final List<double> embedding;

  factory FaceEntry.fromJson(Map<String, dynamic> json) {
    return FaceEntry(
      name: json['name'] as String,
      imagePath: json['imagePath'] as String,
      embedding: (json['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'imagePath': imagePath,
        'embedding': embedding,
      };
}
