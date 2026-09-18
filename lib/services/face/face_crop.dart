import 'dart:math';
import 'dart:ui';

import 'package:image/image.dart' as img;

img.Image cropFaceSquare(
  img.Image source,
  Rect boundingBox, {
  required int size,
  double padding = 0.25,
}) {
  final padX = boundingBox.width * padding;
  final padY = boundingBox.height * padding;

  final left = (boundingBox.left - padX).clamp(0, source.width.toDouble());
  final top = (boundingBox.top - padY).clamp(0, source.height.toDouble());
  final right = (boundingBox.right + padX).clamp(0, source.width.toDouble());
  final bottom = (boundingBox.bottom + padY).clamp(0, source.height.toDouble());

  final maxWidth = source.width - left;
  final maxHeight = source.height - top;
  final side = min(max(right - left, bottom - top), min(maxWidth, maxHeight));
  final safeSide = side < 1 ? 1.0 : side;

  final cropped = img.copyCrop(
    source,
    x: left.round(),
    y: top.round(),
    width: safeSide.round(),
    height: safeSide.round(),
  );

  return img.copyResize(cropped, width: size, height: size);
}
