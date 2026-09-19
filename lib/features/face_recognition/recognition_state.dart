import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

enum RecognitionPhase { starting, running, error }

/// The latest recognition outcome for the face in view.
@immutable
class RecognitionResult {
  const RecognitionResult({
    required this.name,
    required this.percentage,
    required this.isMatch,
  });

  /// The best-matching registered name, or `Unknown` when below the threshold.
  final String name;
  final double percentage;
  final bool isMatch;
}

@immutable
class RecognitionState {
  const RecognitionState({
    this.phase = RecognitionPhase.starting,
    this.message = 'Starting camera…',
    this.controller,
    this.result,
  });

  final RecognitionPhase phase;

  /// Full-screen text while [phase] is not running; the bottom-panel notice
  /// (e.g. "No face detected") while running and there is no [result].
  final String? message;
  final CameraController? controller;
  final RecognitionResult? result;

  RecognitionState copyWith({
    RecognitionPhase? phase,
    String? message,
    bool clearMessage = false,
    CameraController? controller,
    RecognitionResult? result,
    bool clearResult = false,
  }) {
    return RecognitionState(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
      controller: controller ?? this.controller,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}
