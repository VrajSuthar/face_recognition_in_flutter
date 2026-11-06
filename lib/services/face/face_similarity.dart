import 'dart:math';

import 'face_entry.dart';

class FaceMatch {
  const FaceMatch({
    required this.name,
    required this.percentage,
    required this.isMatch,
    this.isAmbiguous = false,
  });

  final String name;
  final double percentage;
  final bool isMatch;

  /// Above [matchThreshold], but a different person scored within
  /// [matchMargin] of [name], so the result is not trusted.
  final bool isAmbiguous;
}

const double matchThreshold = 0.85;

/// How far the best person must score above the runner-up (a *different*
/// person) to count as a match. With hundreds of registered people, look-alikes
/// (siblings, classmates) can both clear [matchThreshold]; picking between them
/// by a hair would be a guess.
const double matchMargin = 0.05;

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

/// Scores each person by their closest registered photo, so several photos
/// of one person never compete with each other, then compares the best person
/// against the runner-up.
FaceMatch? bestMatch(List<double> embedding, List<FaceEntry> entries) {
  if (entries.isEmpty) return null;

  // Keyed by person id, not name: two students can share a name.
  final byPerson = <String, double>{};
  final names = <String, String>{};
  for (final entry in entries) {
    final key = entry.personKey;
    final similarity = cosineSimilarity(embedding, entry.embedding);
    final previous = byPerson[key];
    if (previous == null || similarity > previous) {
      byPerson[key] = similarity;
      names[key] = entry.name;
    }
  }

  var bestKey = '';
  var bestSimilarity = double.negativeInfinity;
  var runnerUp = double.negativeInfinity;
  byPerson.forEach((key, similarity) {
    if (similarity > bestSimilarity) {
      runnerUp = bestSimilarity;
      bestSimilarity = similarity;
      bestKey = key;
    } else if (similarity > runnerUp) {
      runnerUp = similarity;
    }
  });

  final aboveThreshold = bestSimilarity >= matchThreshold;
  final clearWinner = bestSimilarity - runnerUp >= matchMargin;
  final percentage = bestSimilarity.clamp(0.0, 1.0) * 100;
  return FaceMatch(
    name: names[bestKey]!,
    percentage: percentage,
    isMatch: aboveThreshold && clearWinner,
    isAmbiguous: aboveThreshold && !clearWinner,
  );
}
