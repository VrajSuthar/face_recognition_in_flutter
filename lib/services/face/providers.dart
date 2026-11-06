import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'api/face_api_config.dart';
import 'api/face_remote_repository.dart';
import 'face_detector_service.dart';
import 'face_embedder_service.dart';
import 'face_repository.dart';

final faceDetectorServiceProvider = Provider<FaceDetectorService>((ref) {
  final service = FaceDetectorService();
  ref.onDispose(service.close);
  return service;
});

/// Slower but more precise landmarks; used for registration photos.
final enrollmentDetectorServiceProvider = Provider<FaceDetectorService>((ref) {
  final service = FaceDetectorService(mode: FaceDetectorMode.accurate);
  ref.onDispose(service.close);
  return service;
});

final faceEmbedderServiceProvider = FutureProvider<FaceEmbedderService>((
  ref,
) async {
  final service = await FaceEmbedderService.load();
  ref.onDispose(service.close);
  return service;
});

final faceRepositoryProvider = FutureProvider<FaceRepository>((ref) {
  return FaceRepository.forAppDocuments();
});

final faceRemoteRepositoryProvider = Provider<FaceRemoteRepository>((ref) {
  final remote = FaceRemoteRepository(ref.watch(faceApiConfigProvider));
  ref.onDispose(remote.close);
  return remote;
});
