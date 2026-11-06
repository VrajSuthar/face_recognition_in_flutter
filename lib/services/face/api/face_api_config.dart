import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the face API lives. The API is open (no authentication).
///
/// Set at build time, e.g.
/// `flutter run --dart-define=FACE_API_BASE_URL=http://192.168.1.20:8000`.
/// On a real phone this must be the computer's LAN IP, not `localhost`
/// (which would be the phone itself); see docs/FACE_SYNC_API.md § 7.
class FaceApiConfig {
  const FaceApiConfig({required this.baseUrl});

  final String baseUrl;

  bool get isConfigured => baseUrl.isNotEmpty;

  static const fromEnvironment = FaceApiConfig(
    baseUrl: String.fromEnvironment('FACE_API_BASE_URL'),
  );
}

final faceApiConfigProvider = Provider<FaceApiConfig>(
  (ref) => FaceApiConfig.fromEnvironment,
);
