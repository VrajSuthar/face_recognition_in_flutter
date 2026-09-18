import 'dart:math';

import 'face_entry.dart';

class FaceMatch {
  const FaceMatch({
    required this.name,
    required this.percentage,
    required this.isMatch,
  });

  final String name;
  final double percentage;
  final bool isMatch;
}

const matchThreshold = 0.65;

double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length || a.isEmpty) return 0;

  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (sqrt(normA) * sqrt(normB));
}

FaceMatch? bestMatch(List<double> embedding, List<FaceEntry> entries) {
  if (entries.isEmpty) return null;

  var best = entries.first;
  var bestSimilarity = cosineSimilarity(embedding, best.embedding);
  for (final entry in entries.skip(1)) {
    final similarity = cosineSimilarity(embedding, entry.embedding);
    if (similarity > bestSimilarity) {
      bestSimilarity = similarity;
      best = entry;
    }
  }

  final percentage = bestSimilarity.clamp(0.0, 1.0) * 100;
  return FaceMatch(
    name: best.name,
    percentage: percentage,
    isMatch: bestSimilarity >= matchThreshold,
  );
}
