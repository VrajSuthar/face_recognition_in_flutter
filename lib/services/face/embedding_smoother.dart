import 'dart:math';

import 'face_similarity.dart';

/// Averages the embeddings of consecutive frames of the same face so a single
/// blurry or oddly-lit frame can't swing the match score.
class EmbeddingSmoother {
  EmbeddingSmoother({this.window = 5, this.resetBelow = 0.4});

  /// How many recent frames are averaged.
  final int window;

  /// A new embedding this dissimilar (cosine) to the running average is
  /// treated as a different face and restarts the window.
  final double resetBelow;

  final List<List<double>> _recent = [];

  /// Adds [embedding] and returns the L2-normalised average of the window.
  List<double> add(List<double> embedding) {
    final unit = _normalise(embedding);
    if (_recent.isNotEmpty && cosineSimilarity(unit, _mean()) < resetBelow) {
      _recent.clear();
    }
    _recent.add(unit);
    if (_recent.length > window) _recent.removeAt(0);
    return _normalise(_mean());
  }

  void reset() => _recent.clear();

  List<double> _mean() {
    final sum = List<double>.filled(_recent.first.length, 0);
    for (final e in _recent) {
      for (var i = 0; i < sum.length; i++) {
        sum[i] += e[i];
      }
    }
    return sum;
  }

  static List<double> _normalise(List<double> v) {
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = sqrt(norm);
    if (norm == 0) return v;
    return [for (final x in v) x / norm];
  }
}
