import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonText extends StatelessWidget {
  final String text;
  final bool useTranslation;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? textScaleFactor;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextWidthBasis? textWidthBasis;

  const CommonText(
    this.text, {
    Key? key,
    this.useTranslation = true,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.textScaleFactor,
    this.textDirection,
    this.softWrap,
    this.textWidthBasis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayText = useTranslation ? text : text;
    return Text(
      displayText,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      textScaleFactor: textScaleFactor,
      textDirection: textDirection,
      softWrap: softWrap,
      textWidthBasis: textWidthBasis,
    );
  }
}
