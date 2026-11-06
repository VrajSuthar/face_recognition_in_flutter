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

    test('several photos of one person do not count as a close runner-up', () {
      const alice2 = FaceEntry(name: 'Alice', imagePath: 'a2.png', embedding: [0.99, 0.1, 0]);
      final match = bestMatch([1, 0, 0], [alice, alice2, bob]);
      expect(match!.name, 'Alice');
      expect(match.isMatch, isTrue);
      expect(match.isAmbiguous, isFalse);
    });

    test('two different people scoring too close together is ambiguous, not a match', () {
      const twin = FaceEntry(name: 'Twin', imagePath: 't.png', embedding: [0.99, 0.12, 0]);
      final match = bestMatch([1, 0.05, 0], [alice, twin, bob]);
      expect(match!.isMatch, isFalse);
      expect(match.isAmbiguous, isTrue);
    });

    test('a clear winner far ahead of the next person is a match', () {
      final match = bestMatch([1, 0.05, 0], [alice, bob]);
      expect(match!.name, 'Alice');
      expect(match.isMatch, isTrue);
    });

    test('two people with the same name are compared as different people', () {
      const a = FaceEntry(name: 'Aarav', imagePath: 'a', embedding: [1, 0, 0], personId: 'stu_1');
      const b = FaceEntry(name: 'Aarav', imagePath: 'b', embedding: [0.99, 0.12, 0], personId: 'stu_2');
      final match = bestMatch([1, 0.05, 0], [a, b]);
      expect(match!.isAmbiguous, isTrue);
    });
  });
}
