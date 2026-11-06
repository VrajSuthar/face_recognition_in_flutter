import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'face_api_config.dart';
import 'face_api_models.dart';

class FaceApiException implements Exception {
  const FaceApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Fetches people and face photos from the school's server.
///
/// Photos are downloaded into memory only ([downloadPhoto] returns bytes);
/// nothing is written to the phone's storage here. See docs/FACE_SYNC_API.md
/// for the endpoints.
class FaceRemoteRepository {
  FaceRemoteRepository(this.config, {http.Client? client})
    : _client = client ?? http.Client();

  final FaceApiConfig config;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  static const _headers = {'Accept': 'application/json'};

  /// One page of people changed since [since] (everyone when null).
  Future<SyncPage> fetchSyncPage({String? since, String? cursor}) async {
    final uri = Uri.parse('${config.baseUrl}/api/faces/sync').replace(
      queryParameters: {
        'since': ?since,
        'cursor': ?cursor,
      },
    );
    final response = await _send(() => _client.get(uri, headers: _headers));
    try {
      return SyncPage.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } catch (e) {
      throw FaceApiException('The server sent an unexpected response: $e');
    }
  }

  /// The image file at [url], as bytes in memory.
  Future<Uint8List> downloadPhoto(String url) async {
    final response = await _send(() => _client.get(Uri.parse(url)));
    return response.bodyBytes;
  }

  /// Tells the server a photo could not be used (e.g. no face found), so the
  /// office can upload a better one. Best effort: failures are ignored.
  Future<void> reportPhotoProblem(String photoId, String reason) async {
    try {
      await _client
          .post(
            Uri.parse('${config.baseUrl}/api/faces/photo-status'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'photoId': photoId,
              'status': 'rejected',
              'reason': reason,
            }),
          )
          .timeout(_timeout);
    } catch (_) {}
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } catch (e) {
      throw FaceApiException('Could not reach the server: $e');
    }
    if (response.statusCode != 200) {
      throw FaceApiException(
        'The server returned an error (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  void close() => _client.close();
}
