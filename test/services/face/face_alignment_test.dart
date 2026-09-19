import 'dart:math';
import 'dart:ui';

import 'package:face_recognition_app_1/services/face/face_alignment.dart';
import 'package:face_recognition_app_1/services/face/face_crop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _size = 112;

/// The 112x112 template positions: eye A, eye B, mouth A, mouth B.
final _template = [
  const Offset(38.2946, 51.6963),
  const Offset(73.5318, 51.5014),
  const Offset(41.5493, 92.3655),
  const Offset(70.7299, 92.2041),
];

Offset _place(
  Offset p, {
  required double scale,
  required double angle,
  required Offset shift,
}) {
  final c = p - const Offset(56, 56);
  final r = Offset(
    c.dx * cos(angle) - c.dy * sin(angle),
    c.dx * sin(angle) + c.dy * cos(angle),
  );
  return r * scale + const Offset(150, 150) + shift;
}

void _dot(img.Image image, Offset p) {
  img.fillRect(
    image,
    x1: p.dx.round() - 3,
    y1: p.dy.round() - 3,
    x2: p.dx.round() + 3,
    y2: p.dy.round() + 3,
    color: img.ColorRgb8(255, 255, 255),
  );
}

void main() {
  group('estimateSimilarity', () {
    test('recovers a known scale, rotation and translation', () {
      final src = _template
          .map(
            (p) => _place(p, scale: 2, angle: 0.3, shift: const Offset(10, -5)),
          )
          .toList();
      final t = estimateSimilarity(src, _template)!;
      for (var i = 0; i < src.length; i++) {
        final mapped = t.apply(src[i]);
        expect((mapped - _template[i]).distance, lessThan(0.01));
      }
    });

    test('returns null for degenerate (coincident) points', () {
      final same = List.filled(4, const Offset(5, 5));
      expect(estimateSimilarity(same, _template), isNull);
    });
  });

  group('alignFace', () {
    test(
      'puts the eyes on the template even when the face is tilted and scaled',
      () {
        final source = img.Image(width: 320, height: 320);
        img.fill(source, color: img.ColorRgb8(0, 0, 0));
        final pts = _template
            .map(
              (p) => _place(
                p,
                scale: 1.7,
                angle: 0.35,
                shift: const Offset(12, 8),
              ),
            )
            .toList();
        for (final p in pts) {
          _dot(source, p);
        }
        final box = Rect.fromCenter(
          center: const Offset(162, 158),
          width: 190,
          height: 190,
        );

        // Landmarks handed in the "wrong" order must still be handled.
        final flat = [
          pts[1].dx,
          pts[1].dy,
          pts[0].dx,
          pts[0].dy,
          pts[3].dx,
          pts[3].dy,
          pts[2].dx,
          pts[2].dy,
        ];
        final out = alignFace(source, box: box, size: _size, landmarks: flat);

        expect((out.width, out.height), (_size, _size));
        for (final t in _template) {
          expect(out.getPixel(t.dx.round(), t.dy.round()).r, greaterThan(200));
        }
        expect(out.getPixel(56, 8).r, lessThan(50));
      },
    );

    test('falls back to the plain square crop without landmarks', () {
      final source = img.Image(width: 200, height: 200);
      img.fill(source, color: img.ColorRgb8(0, 0, 255));
      img.fillRect(
        source,
        x1: 60,
        y1: 60,
        x2: 139,
        y2: 139,
        color: img.ColorRgb8(255, 0, 0),
      );
      const box = Rect.fromLTWH(60, 60, 80, 80);

      final out = alignFace(source, box: box, size: _size);
      final expected = cropFaceSquare(source, box, size: _size);
      expect(out.getBytes(), expected.getBytes());
    });

    test('falls back when the eye line is implausible (vertical)', () {
      final source = img.Image(width: 200, height: 200);
      img.fill(source, color: img.ColorRgb8(0, 0, 255));
      const box = Rect.fromLTWH(60, 60, 80, 80);
      final out = alignFace(
        source,
        box: box,
        size: _size,
        landmarks: [100, 70, 100, 110, 90, 130, 110, 130],
      );
      expect(
        out.getBytes(),
        cropFaceSquare(source, box, size: _size).getBytes(),
      );
    });
  });
}
