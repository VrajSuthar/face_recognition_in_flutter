import 'dart:ui';

import 'package:face_recognition_app_1/services/face/face_crop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Background colour of every synthetic source image.
final _background = img.ColorRgb8(0, 0, 255);

/// The colour of the "face" marker the crop is expected to capture.
final _marker = img.ColorRgb8(255, 0, 0);

/// A [size]x[size] image filled with [_background], with a [_marker]-coloured
/// rectangle painted at the given inclusive bounds.
img.Image _sourceWithMarker({
  required int size,
  required int markerLeft,
  required int markerTop,
  required int markerWidth,
  required int markerHeight,
}) {
  final image = img.Image(width: size, height: size);
  img.fill(image, color: _background);
  img.fillRect(
    image,
    x1: markerLeft,
    y1: markerTop,
    x2: markerLeft + markerWidth - 1,
    y2: markerTop + markerHeight - 1,
    color: _marker,
  );
  return image;
}

void _expectColor(img.Image image, int x, int y, img.Color expected,
    {String? reason}) {
  final pixel = image.getPixel(x, y);
  expect(
    [pixel.r, pixel.g, pixel.b],
    [expected.r, expected.g, expected.b],
    reason: reason ?? 'pixel ($x, $y)',
  );
}

void main() {
  test('crops and resizes to the requested square size', () {
    final source = img.Image(width: 200, height: 200);
    const box = Rect.fromLTWH(50, 50, 60, 60);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);
  });

  test('crops the region the bounding box actually points at', () {
    // Marker occupies x/y 60..99 of a 200x200 image.
    final source = _sourceWithMarker(
      size: 200,
      markerLeft: 60,
      markerTop: 60,
      markerWidth: 40,
      markerHeight: 40,
    );
    const box = Rect.fromLTWH(60, 60, 40, 40);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);

    // With padding 0.25 the crop is the 60x60 square at (50, 50), so the
    // marker covers the middle 40/60 of the result in both axes. If the crop
    // had been taken from anywhere else (e.g. the origin, as the Android
    // rotated-coordinate bug effectively did), the centre would be background.
    _expectColor(result, 56, 56, _marker, reason: 'centre should be marker');
    _expectColor(result, 40, 40, _marker, reason: 'marker upper-left quadrant');
    _expectColor(result, 72, 72, _marker, reason: 'marker lower-right quadrant');

    // The 0.25 padding ring around the marker must still be background.
    _expectColor(result, 4, 4, _background, reason: 'padding top-left');
    _expectColor(result, 107, 107, _background, reason: 'padding bottom-right');
  });

  test('a box in a different quadrant crops that quadrant, not the centre',
      () {
    // Marker in the lower-right quadrant only.
    final source = _sourceWithMarker(
      size: 200,
      markerLeft: 130,
      markerTop: 140,
      markerWidth: 30,
      markerHeight: 30,
    );
    const box = Rect.fromLTWH(130, 140, 30, 30);

    final result = cropFaceSquare(source, box, size: 112);

    // Crop is the 45x45 square at (122.5, 132.5) -> rounded (123, 133),
    // so the marker still lands across the middle of the result.
    _expectColor(result, 56, 56, _marker, reason: 'centre should be marker');
    _expectColor(result, 4, 4, _background, reason: 'padding top-left');
  });

  test('clamps the crop to the source image bounds near an edge', () {
    final source = _sourceWithMarker(
      size: 100,
      markerLeft: 0,
      markerTop: 0,
      markerWidth: 20,
      markerHeight: 20,
    );
    const box = Rect.fromLTWH(0, 0, 20, 20);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);
    // left/top clamp to 0 and no padding fits above/left of the marker, so
    // the crop starts exactly on the marker.
    _expectColor(result, 4, 4, _marker, reason: 'crop starts on the marker');
  });

  test('a box partly outside the source still yields a valid square', () {
    final source = _sourceWithMarker(
      size: 200,
      markerLeft: 180,
      markerTop: 180,
      markerWidth: 20,
      markerHeight: 20,
    );
    const box = Rect.fromLTWH(180, 180, 40, 40);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);
  });

  test('a box wholly outside the source degrades without crashing', () {
    final source = _sourceWithMarker(
      size: 200,
      markerLeft: 10,
      markerTop: 10,
      markerWidth: 20,
      markerHeight: 20,
    );
    // Entirely past the right/bottom edge: exercises the `safeSide` clamp.
    const box = Rect.fromLTWH(500, 500, 40, 40);

    final result = cropFaceSquare(source, box, size: 112);

    // Content is meaningless here (the crop degenerates to a single pixel);
    // the contract is only that it stays a valid size x size image.
    expect(result.width, 112);
    expect(result.height, 112);
  });

  test('a negative-origin box does not crash and stays square', () {
    final source = _sourceWithMarker(
      size: 200,
      markerLeft: 0,
      markerTop: 0,
      markerWidth: 20,
      markerHeight: 20,
    );
    const box = Rect.fromLTWH(-60, -60, 40, 40);

    final result = cropFaceSquare(source, box, size: 112);

    expect(result.width, 112);
    expect(result.height, 112);
  });
}
