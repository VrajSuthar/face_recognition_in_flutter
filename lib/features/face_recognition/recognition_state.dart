import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

enum RecognitionPhase { starting, running, error }

/// A face the detector is currently tracking, in the coordinate space of
/// [frameSize] (the frame ML Kit measured against).
@immutable
class TrackedFace {
  const TrackedFace({
    required this.box,
    required this.frameSize,
    this.label,
    this.isMatch = false,
  });

  final Rect box;
  final Size frameSize;
  final String? label;
  final bool isMatch;

  TrackedFace copyWith({
    Rect? box,
    Size? frameSize,
    String? label,
    bool? isMatch,
  }) {
    return TrackedFace(
      box: box ?? this.box,
      frameSize: frameSize ?? this.frameSize,
      label: label ?? this.label,
      isMatch: isMatch ?? this.isMatch,
    );
  }
}

@immutable
class RecognitionState {
  const RecognitionState({
    this.phase = RecognitionPhase.starting,
    this.message = 'Starting camera…',
    this.controller,
    this.face,
  });

  final RecognitionPhase phase;

  /// Full-screen text while [phase] is not running; a small transient notice
  /// (e.g. "No face detected") over the preview while running.
  final String? message;
  final CameraController? controller;
  final TrackedFace? face;

  RecognitionState copyWith({
    RecognitionPhase? phase,
    String? message,
    bool clearMessage = false,
    CameraController? controller,
    TrackedFace? face,
    bool clearFace = false,
  }) {
    return RecognitionState(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
      controller: controller ?? this.controller,
      face: clearFace ? null : (face ?? this.face),
    );
  }
}
