import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'face_crop.dart';

/// Where the eyes and mouth corners sit in the canonical 112x112 aligned face
/// (the ArcFace / MobileFaceNet template): eye A, eye B, mouth A, mouth B, with
/// "A" being the one further left in the image.
const _template112 = [
  Offset(38.2946, 51.6963),
  Offset(73.5318, 51.5014),
  Offset(41.5493, 92.3655),
  Offset(70.7299, 92.2041),
];

/// `dst = [a -b; b a] * src + (tx, ty)` — rotation + uniform scale + shift.
class SimilarityTransform {
  const SimilarityTransform(this.a, this.b, this.tx, this.ty);

  final double a;
  final double b;
  final double tx;
  final double ty;

  Offset apply(Offset p) =>
      Offset(a * p.dx - b * p.dy + tx, b * p.dx + a * p.dy + ty);

  double get scale => sqrt(a * a + b * b);
}

/// Least-squares similarity transform mapping [src] onto [dst], or null when
/// the source points are degenerate.
SimilarityTransform? estimateSimilarity(List<Offset> src, List<Offset> dst) {
  assert(src.length == dst.length && src.isNotEmpty);
  final n = src.length;
  var sMean = Offset.zero;
  var dMean = Offset.zero;
  for (var i = 0; i < n; i++) {
    sMean += src[i];
    dMean += dst[i];
  }
  sMean /= n.toDouble();
  dMean /= n.toDouble();

  var num1 = 0.0;
  var num2 = 0.0;
  var denom = 0.0;
  for (var i = 0; i < n; i++) {
    final s = src[i] - sMean;
    final d = dst[i] - dMean;
    num1 += s.dx * d.dx + s.dy * d.dy;
    num2 += s.dx * d.dy - s.dy * d.dx;
    denom += s.dx * s.dx + s.dy * s.dy;
  }
  if (denom < 1e-9) return null;

  final a = num1 / denom;
  final b = num2 / denom;
  final tx = dMean.dx - (a * sMean.dx - b * sMean.dy);
  final ty = dMean.dy - (b * sMean.dx + a * sMean.dy);
  return SimilarityTransform(a, b, tx, ty);
}

/// Produces the [size]x[size] face the embedder expects.
///
/// With usable [landmarks] — a flat `[eyeX, eyeY, eyeX, eyeY, mouthX, mouthY,
/// mouthX, mouthY]`, each pair in either order — the face is rotated, scaled
/// and shifted so the eyes and mouth land on the canonical template positions.
/// Without landmarks, or when they look implausible (e.g. a sideways frame),
/// it falls back to the plain padded square crop.
img.Image alignFace(
  img.Image source, {
  required Rect box,
  required int size,
  List<double>? landmarks,
}) {
  final transform = landmarks == null
      ? null
      : _transformFor(landmarks, box, size);
  if (transform == null) return cropFaceSquare(source, box, size: size);
  return _warp(source, transform, size);
}

SimilarityTransform? _transformFor(List<double> l, Rect box, int size) {
  if (l.length != 8) return null;
  var eyeA = Offset(l[0], l[1]);
  var eyeB = Offset(l[2], l[3]);
  var mouthA = Offset(l[4], l[5]);
  var mouthB = Offset(l[6], l[7]);
  // ML Kit's left/right naming is subject-relative; sort by image x instead.
  if (eyeA.dx > eyeB.dx) (eyeA, eyeB) = (eyeB, eyeA);
  if (mouthA.dx > mouthB.dx) (mouthA, mouthB) = (mouthB, mouthA);

  final eyeVector = eyeB - eyeA;
  final eyeDistance = eyeVector.distance;
  if (box.width <= 0 ||
      eyeDistance / box.width < 0.2 ||
      eyeDistance / box.width > 0.8) {
    return null;
  }
  // A tilt beyond ~50° means the frame is not upright; alignment would be
  // guessing.
  if (atan2(eyeVector.dy, eyeVector.dx).abs() > 50 * pi / 180) return null;
  // Mouth must be below the eyes.
  if ((mouthA.dy + mouthB.dy) / 2 <= (eyeA.dy + eyeB.dy) / 2) return null;

  final k = size / 112;
  final dst = _template112.map((p) => p * k).toList();
  final t = estimateSimilarity([eyeA, eyeB, mouthA, mouthB], dst);
  if (t == null || !t.scale.isFinite || t.scale <= 0) return null;
  return t;
}

img.Image _warp(img.Image source, SimilarityTransform t, int size) {
  final out = img.Image(width: size, height: size);
  final det = t.a * t.a + t.b * t.b;
  final maxX = source.width - 1;
  final maxY = source.height - 1;

  for (var v = 0; v < size; v++) {
    for (var u = 0; u < size; u++) {
      // Invert dst = R * src + t.
      final dx = u - t.tx;
      final dy = v - t.ty;
      final sx = ((t.a * dx + t.b * dy) / det).clamp(0.0, maxX.toDouble());
      final sy = ((-t.b * dx + t.a * dy) / det).clamp(0.0, maxY.toDouble());

      final x0 = sx.floor();
      final y0 = sy.floor();
      final x1 = min(x0 + 1, maxX);
      final y1 = min(y0 + 1, maxY);
      final fx = sx - x0;
      final fy = sy - y0;

      final p00 = source.getPixel(x0, y0);
      final p10 = source.getPixel(x1, y0);
      final p01 = source.getPixel(x0, y1);
      final p11 = source.getPixel(x1, y1);

      num mix(num c00, num c10, num c01, num c11) =>
          (c00 * (1 - fx) + c10 * fx) * (1 - fy) +
          (c01 * (1 - fx) + c11 * fx) * fy;

      out.setPixelRgb(
        u,
        v,
        mix(p00.r, p10.r, p01.r, p11.r).round(),
        mix(p00.g, p10.g, p01.g, p11.g).round(),
        mix(p00.b, p10.b, p01.b, p11.b).round(),
      );
    }
  }
  return out;
}
