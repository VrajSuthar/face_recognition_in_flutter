import 'dart:ui';

Rect scaleRect(Rect source, Size fromSize, Size toSize) {
  final scaleX = toSize.width / fromSize.width;
  final scaleY = toSize.height / fromSize.height;
  return Rect.fromLTRB(
    source.left * scaleX,
    source.top * scaleY,
    source.right * scaleX,
    source.bottom * scaleY,
  );
}
