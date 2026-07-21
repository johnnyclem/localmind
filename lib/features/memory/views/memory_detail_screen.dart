import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../git_mind/views/components/memory_history_sheet.dart';
import '../data/models/memory.dart';
import '../providers/memory_providers.dart';
import 'components/edit_memory_sheet.dart';
import 'components/memory_card.dart' show formatMemoryRelativeTime;

/// Memory detail screen (mobile PRD T-M6-08/09/10) — full content,
/// provenance receipt, linked memories/artifacts, edit, and forget.
/// "Connect a memory" (T-M6-11) is out of scope for this pass (not in the
/// v1 build list) — see the gaps note in the epic report.
class MemoryDetailScreen extends ConsumerWidget {
  final String memoryId;

  const MemoryDetailScreen({super.key, required this.memoryId});

  void _openHistory(MemoryDetail memory, BuildContext context) {
    showMemoryHistorySheet(
      context,
      memoryId: memory.id,
      currentTitle: memory.title,
      currentContent: memory.content,
      currentTags: memory.tags,
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    MemoryDetail memory,
  ) async {
    final message = await showEditMemorySheet(context, memory);
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _forget(
    BuildContext context,
    WidgetRef ref,
    MemoryDetail memory,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forget this memory?'),
        content: Text(
          '"${memory.title}" will be removed from your wiki. This cannot be undone from here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(memoryApiServiceProvider).delete(memory.id);
      ref.read(memoryListProvider.notifier).removeLocally(memory.id);
      if (context.mounted) context.pop();
    } on HyperVaultApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not forget that memory — check your connection.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openRelated(
    BuildContext context,
    WidgetRef ref,
    MemoryRelatedRef related,
  ) async {
    if (related.id.isNotEmpty) {
      context.push(AppRoutes.memoryDetail, extra: related.id);
      return;
    }
    // Search results only carry titles (no id) — fall back to resolving it
    // through recall before we can navigate.
    try {
      final response = await ref
          .read(memoryApiServiceProvider)
          .search(related.title);
      final match = response.results
          .where((r) => r.title == related.title)
          .toList();
      if (match.isNotEmpty && context.mounted) {
        context.push(AppRoutes.memoryDetail, extra: match.first.id);
        return;
      }
    } catch (_) {
      // fall through to the not-found snackbar below
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not locate "${related.title}" — try searching for it.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(memoryDetailProvider(memoryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
          detailAsync.when(
            data: (memory) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'History',
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedGitCommit),
                  onPressed: () => _openHistory(memory, context),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedEdit02),
                  onPressed: () => _edit(context, ref, memory),
                ),
                IconButton(
                  tooltip: 'Forget',
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
                  onPressed: () => _forget(context, ref, memory),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (memory) => _MemoryDetailBody(
          memory: memory,
          onOpenRelated: (r) => _openRelated(context, ref, r),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlertCircle,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  err is HyperVaultApiException
                      ? err.message
                      : 'Could not load that memory.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref
                      .read(memoryDetailProvider(memoryId).notifier)
                      .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryDetailBody extends StatelessWidget {
  final MemoryDetail memory;
  final void Function(MemoryRelatedRef) onOpenRelated;

  const _MemoryDetailBody({required this.memory, required this.onOpenRelated});

  String _humanizeKey(String key) => key
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          memory.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              formatMemoryRelativeTime(memory.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (memory.source != null && memory.source!.isNotEmpty) ...[
              const SizedBox(width: 12),
              ShadBadge.outline(child: Text(memory.source!)),
            ],
            const SizedBox(width: 12),
            HugeIcon(
              icon: HugeIcons.strokeRoundedGitCommit,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '${memory.revisionCount} revision${memory.revisionCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (memory.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: memory.tags
                .map((tag) => ShadBadge.secondary(child: Text('#$tag')))
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        ShadCard(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            memory.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
        if (memory.provenance.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Provenance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ShadCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: memory.provenance.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${_humanizeKey(e.key)}: ${e.value}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (memory.related.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Linked memories', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: memory.related
                .map(
                  (r) => GestureDetector(
                    onTap: () => onOpenRelated(r),
                    child: ShadBadge.outline(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(r.title),
                          const SizedBox(width: 4),
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (memory.artifacts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Linked artifacts', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: memory.artifacts
                .map(
                  (a) => ShadBadge.outline(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedShare01,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(a.slug ?? a.title),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
