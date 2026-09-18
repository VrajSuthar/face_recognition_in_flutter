import 'package:face_recognition_app_1/services/face/face_entry.dart';
import 'package:face_recognition_app_1/services/face/face_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cosineSimilarity', () {
    test('identical vectors have similarity 1', () {
      expect(cosineSimilarity([1, 0, 0], [1, 0, 0]), closeTo(1.0, 1e-9));
    });

    test('orthogonal vectors have similarity 0', () {
      expect(cosineSimilarity([1, 0], [0, 1]), closeTo(0.0, 1e-9));
    });

    test('returns 0 for empty vectors', () {
      expect(cosineSimilarity([], []), 0);
    });

    test('returns 0 when either vector is all zeros', () {
      expect(cosineSimilarity([0, 0], [1, 1]), 0);
    });
  });

  group('bestMatch', () {
    const alice = FaceEntry(name: 'Alice', imagePath: 'a.png', embedding: [1, 0, 0]);
    const bob = FaceEntry(name: 'Bob', imagePath: 'b.png', embedding: [0, 1, 0]);

    test('returns null when there are no registered entries', () {
      expect(bestMatch([1, 0, 0], []), isNull);
    });

    test('picks the closest entry and marks it a match above threshold', () {
      final match = bestMatch([1, 0, 0], [alice, bob]);
      expect(match, isNotNull);
      expect(match!.name, 'Alice');
      expect(match.isMatch, isTrue);
      expect(match.percentage, closeTo(100, 1e-6));
    });

    test('still returns the closest entry but marks isMatch false below threshold', () {
      final farVector = [0.0, 0.0, 1.0]; // orthogonal to both alice and bob
      final match = bestMatch(farVector, [alice, bob]);
      expect(match, isNotNull);
      expect(match!.isMatch, isFalse);
      expect(match.percentage, closeTo(0, 1e-6));
    });
  });
}
