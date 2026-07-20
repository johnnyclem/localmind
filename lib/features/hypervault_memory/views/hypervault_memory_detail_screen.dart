import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../../hypervault/providers/hypervault_providers.dart';
import '../data/models/hv_memory_detail.dart';
import '../data/models/hv_memory_provenance.dart';
import '../providers/hypervault_memory_providers.dart';
import 'components/edit_memory_sheet.dart';
import 'hypervault_memory_history_screen.dart';

/// One wiki page (T-M6-08 through T-M6-10): full content, provenance
/// receipt, linked memories, linked artifacts, and edit/forget/history
/// actions.
class HypervaultMemoryDetailScreen extends ConsumerWidget {
  final String memoryId;

  const HypervaultMemoryDetailScreen({super.key, required this.memoryId});

  Future<void> _forget(
    BuildContext context,
    WidgetRef ref,
    HvMemoryDetail detail,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Really forget?'),
        content: Text(
          '"${detail.memory.title}" will be forgotten (its history stays revertible).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final service = ref.read(hyperVaultMemoryServiceProvider);
      final branch = ref.read(hyperVaultActiveBranchProvider);
      final message = await service.forget(memoryId, branch: branch);
      ref.invalidate(hyperVaultMemoryBrowseProvider);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not forget: $e')));
    }
  }

  Future<void> _openArtifact(WidgetRef ref, String slug) async {
    final baseUrl = ref.read(hyperVaultBaseUrlProvider);
    final uri = Uri.tryParse('$baseUrl/a/$slug');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(hyperVaultMemoryDetailProvider(memoryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
          detailAsync.maybeWhen(
            data: (detail) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'History',
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedTransactionHistory,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HypervaultMemoryHistoryScreen(
                        memoryId: memoryId,
                        title: detail.memory.title,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPencilEdit01,
                  ),
                  onPressed: () => showEditMemorySheet(context, ref, detail),
                ),
                IconButton(
                  tooltip: 'Forget',
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
                  onPressed: () => _forget(context, ref, detail),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: detailAsync.when(
          data: (detail) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.memory.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ShadBadge.secondary(
                      child: Text(
                        detail.memory.source,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    for (final tag in detail.memory.tags)
                      ShadBadge.outline(
                        child: Text(tag, style: const TextStyle(fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (detail.provenance != null)
                  _ProvenanceLine(
                    provenance: detail.provenance!,
                    revisionCount: detail.revisionCount,
                  ),
                const SizedBox(height: 16),
                ShadCard(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    detail.memory.content,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                if (detail.related.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Linked memories', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final link in detail.related)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const HugeIcon(
                        icon: HugeIcons.strokeRoundedLink01,
                        size: 18,
                      ),
                      title: Text(link.title),
                      subtitle: link.summary.isNotEmpty
                          ? Text(
                              link.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              HypervaultMemoryDetailScreen(memoryId: link.id),
                        ),
                      ),
                    ),
                ],
                if (detail.artifacts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Linked artifacts', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final artifact in detail.artifacts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const HugeIcon(
                        icon: HugeIcons.strokeRoundedFile02,
                        size: 18,
                      ),
                      title: Text(artifact.title),
                      subtitle: Text(artifact.type),
                      trailing: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowUpRight01,
                        size: 16,
                      ),
                      onTap: () => _openArtifact(ref, artifact.slug),
                    ),
                ],
              ],
            ),
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                err is HvApiError
                    ? err.error
                    : 'Could not load that memory: $err',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProvenanceLine extends StatelessWidget {
  final HvMemoryProvenance provenance;
  final int revisionCount;

  const _ProvenanceLine({
    required this.provenance,
    required this.revisionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final commitId = provenance.commitId;
    final shortId = commitId.length > 8 ? commitId.substring(0, 8) : commitId;
    final committedAt = provenance.committedAt;
    final when = committedAt != null
        ? DateFormat.yMMMd().add_jm().format(committedAt)
        : '';
    return Text(
      'Last commit $shortId · ${provenance.message} · by ${provenance.authorLabel}'
      '${when.isNotEmpty ? ' · $when' : ''} · $revisionCount revision${revisionCount == 1 ? '' : 's'}',
      style: theme.textTheme.labelSmall?.copyWith(color: muted),
    );
  }
}
