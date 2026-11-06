import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/face/api/face_api_config.dart';
import '../../services/face/face_enrollment.dart';
import '../../services/face/face_repository.dart';
import '../../services/face/face_sync_service.dart';
import '../../services/face/providers.dart';

@immutable
class FaceSyncState {
  const FaceSyncState({
    this.isSyncing = false,
    this.progress,
    this.report,
    this.error,
    this.lastSync,
  });

  final bool isSyncing;
  final SyncProgress? progress;
  final SyncReport? report;
  final String? error;

  /// Server time of the last completed sync, or null if never synced.
  final String? lastSync;
}

final faceSyncProvider =
    NotifierProvider.autoDispose<FaceSyncNotifier, FaceSyncState>(
      FaceSyncNotifier.new,
    );

class FaceSyncNotifier extends Notifier<FaceSyncState> {
  @override
  FaceSyncState build() {
    Future.microtask(_loadLastSync);
    return const FaceSyncState();
  }

  Future<void> _loadLastSync() async {
    try {
      final repository = await ref.read(faceRepositoryProvider.future);
      final lastSync = await repository.readSyncState(lastSyncKey);
      if (ref.mounted && !state.isSyncing) {
        state = FaceSyncState(lastSync: lastSync, report: state.report);
      }
    } catch (_) {
      // Only informational; the sync button still works.
    }
  }

  Future<void> sync() async {
    if (state.isSyncing) return;
    if (!ref.read(faceApiConfigProvider).isConfigured) {
      state = FaceSyncState(
        lastSync: state.lastSync,
        error:
            'No server is set. Run the app with '
            '--dart-define=FACE_API_BASE_URL=http://<computer-ip>:8000',
      );
      return;
    }

    state = FaceSyncState(isSyncing: true, lastSync: state.lastSync);
    try {
      final FaceRepository repository = await ref.read(
        faceRepositoryProvider.future,
      );
      final detector = ref.read(enrollmentDetectorServiceProvider);
      final embedder = await ref.read(faceEmbedderServiceProvider.future);
      final tempDir = await getTemporaryDirectory();
      final service = FaceSyncService(
        remote: ref.read(faceRemoteRepositoryProvider),
        repository: repository,
        enrollPhoto: (bytes) => enrollFacePhoto(
          bytes,
          detector: detector,
          embedder: embedder,
          tempDir: tempDir,
        ),
      );
      final report = await service.sync(
        onProgress: (progress) {
          if (ref.mounted) {
            state = FaceSyncState(
              isSyncing: true,
              progress: progress,
              lastSync: state.lastSync,
            );
          }
        },
      );
      if (!ref.mounted) return;
      state = FaceSyncState(
        report: report,
        lastSync: await repository.readSyncState(lastSyncKey),
      );
    } catch (e) {
      if (ref.mounted) {
        state = FaceSyncState(lastSync: state.lastSync, error: 'Sync failed: $e');
      }
    }
  }
}
