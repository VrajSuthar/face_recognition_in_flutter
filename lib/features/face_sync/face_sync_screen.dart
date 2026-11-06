import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/face/face_sync_service.dart';
import 'face_sync_notifier.dart';

class FaceSyncScreen extends ConsumerWidget {
  const FaceSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faceSyncProvider);
    final theme = Theme.of(context);

    return PopScope(
      // Leaving mid-sync would stop it halfway; the next sync would resume,
      // but it is clearer to make people wait.
      canPop: !state.isSyncing,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sync Faces from Server')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              state.lastSync == null
                  ? 'Never synced. The first sync downloads every teacher and '
                        'student and can take several minutes.'
                  : 'Last synced: ${state.lastSync}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: state.isSyncing
                  ? null
                  : ref.read(faceSyncProvider.notifier).sync,
              icon: const Icon(Icons.sync),
              label: Text(state.isSyncing ? 'Syncing…' : 'Sync now'),
            ),
            if (state.isSyncing) ...[
              const SizedBox(height: 24),
              _Progress(progress: state.progress),
              const SizedBox(height: 8),
              Text(
                'Keep the app open until the sync finishes.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (state.report != null) ...[
              const SizedBox(height: 24),
              _ReportCard(report: state.report!),
            ],
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.progress});

  final SyncProgress? progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final total = p?.peopleTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: p == null || total == null || total == 0
              ? null
              : p.peopleDone / total,
        ),
        const SizedBox(height: 8),
        Text(
          p == null
              ? 'Contacting the server…'
              : '${p.peopleDone}${total == null ? '' : ' of $total'} people'
                    '${p.currentName == null ? '' : ' — ${p.currentName}'}',
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final SyncReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sync complete', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('People updated: ${report.peopleUpdated}'),
            Text('People removed: ${report.peopleDeleted}'),
            Text('Photos added: ${report.photosAdded}'),
            Text('Photos unchanged: ${report.photosUnchanged}'),
            Text('Photos removed: ${report.photosRemoved}'),
            if (report.problems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${report.problems.length} photo(s) could not be used:',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              for (final problem in report.problems) Text('• $problem'),
            ],
          ],
        ),
      ),
    );
  }
}
