import 'package:face_recognition_app_1/services/face/embedding_smoother.dart';
import 'package:face_recognition_app_1/services/face/face_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first embedding comes back (normalised) unchanged in direction', () {
    final s = EmbeddingSmoother();
    final out = s.add([3, 0]);
    expect(cosineSimilarity(out, [1, 0]), closeTo(1, 1e-9));
  });

  test('averages nearby embeddings', () {
    final s = EmbeddingSmoother();
    s.add([1, 0.2]);
    final out = s.add([1, -0.2]);
    expect(cosineSimilarity(out, [1, 0]), closeTo(1, 1e-9));
  });

  test('only the last `window` embeddings contribute', () {
    final s = EmbeddingSmoother(window: 2);
    s.add([1, 0.3]);
    s.add([1, 0.3]);
    s.add([1, -0.3]);
    final out = s.add([1, -0.3]);
    // Window holds only the two [1,-0.3] frames.
    expect(cosineSimilarity(out, [1, -0.3]), closeTo(1, 1e-9));
  });

  test('a very different embedding restarts the window (new person)', () {
    final s = EmbeddingSmoother();
    s.add([1, 0]);
    s.add([1, 0]);
    final out = s.add([0, 1]);
    expect(cosineSimilarity(out, [0, 1]), closeTo(1, 1e-9));
  });

  test('reset clears history', () {
    final s = EmbeddingSmoother();
    s.add([1, 0]);
    s.reset();
    final out = s.add([0, 1]);
    expect(cosineSimilarity(out, [0, 1]), closeTo(1, 1e-9));
  });
}
