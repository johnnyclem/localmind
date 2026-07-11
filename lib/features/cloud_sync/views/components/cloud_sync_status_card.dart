import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/cloud_sync_models.dart';

class CloudSyncStatusCard extends StatelessWidget {
  const CloudSyncStatusCard({super.key, required this.status});

  final CloudSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = switch (status.phase) {
      CloudSyncPhase.synced => Colors.green,
      CloudSyncPhase.syncing => Colors.blue,
      CloudSyncPhase.error || CloudSyncPhase.locked => Colors.red,
      _ => Colors.grey,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status.message ?? l10n.cloud_sync_description,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (status.phase == CloudSyncPhase.syncing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.cloud_sync_last_synced}: '
              '${status.lastSyncedAt?.toLocal().toString() ?? l10n.cloud_sync_never}',
            ),
            if (status.conflictCount > 0)
              Text('${l10n.cloud_sync_conflicts}: ${status.conflictCount}'),
            for (final warning in status.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  warning,
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
