import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../data/models/hv_artifact.dart';
import '../../providers/hv_vault_providers.dart';

/// This artifact's known edges, with a remove action per edge
/// (docs/mobile/prd/05-connections-sharing.md T-M5-02). Edges only resolve
/// to a readable label once this device has learned the artifact's database
/// id (see [HvVaultCache]) — until then they're listed by their raw id.
class ConnectionsSection extends ConsumerWidget {
  final HvArtifact artifact;

  const ConnectionsSection({super.key, required this.artifact});

  Future<void> _remove(BuildContext context, WidgetRef ref, String edgeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove connection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(hvConnectionsProvider.notifier).disconnect(edgeId);
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(hvVaultUserIdProvider);
    final connectionsAsync = ref.watch(hvConnectionsProvider);
    final artifacts = ref.watch(hvArtifactsProvider).value ?? const <HvArtifact>[];

    return connectionsAsync.when(
      data: (data) {
        if (userId == null) return const SizedBox.shrink();
        final selfId = ref.read(hvVaultCacheProvider).idForSlug(userId, artifact.slug);
        if (selfId == null) {
          return Text(
            'Use Connect once and this artifact\'s edges will start listing here.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          );
        }
        final edges = data.all.where((e) => e.aId == selfId || e.bId == selfId).toList();
        if (edges.isEmpty) {
          return Text(
            'No connections yet.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: edges.map((edge) {
            final otherId = edge.aId == selfId ? edge.bId : edge.aId;
            final otherSlug = ref.read(hvVaultCacheProvider).slugForId(userId, otherId);
            final other = otherSlug == null
                ? null
                : artifacts.where((a) => a.slug == otherSlug).firstOrNull;
            final label = other?.title ?? otherSlug ?? 'Item ${otherId.substring(0, otherId.length.clamp(0, 8))}…';
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: HugeIcon(
                icon: edge.isManual
                    ? HugeIcons.strokeRoundedLinkSquare01
                    : HugeIcons.strokeRoundedGlobalRefresh,
                size: 18,
              ),
              title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(edge.isManual ? 'manual' : 'auto'),
              trailing: IconButton(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16),
                onPressed: () => _remove(context, ref, edge.id),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text(
        e is HvApiError ? e.error : 'Could not load connections.',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }
}
