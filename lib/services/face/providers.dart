import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'face_detector_service.dart';
import 'face_embedder_service.dart';
import 'face_repository.dart';

final faceDetectorServiceProvider = Provider<FaceDetectorService>((ref) {
  final service = FaceDetectorService();
  ref.onDispose(service.close);
  return service;
});

final faceEmbedderServiceProvider =
    FutureProvider<FaceEmbedderService>((ref) async {
  final service = await FaceEmbedderService.load();
  ref.onDispose(service.close);
  return service;
});

final faceRepositoryProvider = FutureProvider<FaceRepository>((ref) {
  return FaceRepository.forAppDocuments();
});
