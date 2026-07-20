import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../data/models/hv_memory_revision.dart';
import '../data/models/hv_mind_diff.dart';
import '../providers/hypervault_memory_providers.dart';
import 'components/diff_hunk_view.dart';

/// Revision timeline (T-M7-06) with an optional per-revision diff toggle
/// (T-M7-07). Newest first; op badge, commit message, author, timestamp,
/// and a branch badge when it differs from the memory's own branch.
class HypervaultMemoryHistoryScreen extends ConsumerWidget {
  final String memoryId;
  final String title;

  const HypervaultMemoryHistoryScreen({
    super.key,
    required this.memoryId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(hyperVaultMemoryHistoryProvider(memoryId));

    return Scaffold(
      appBar: AppBar(title: Text('History — $title')),
      body: SafeArea(
        child: historyAsync.when(
          data: (revisions) {
            if (revisions.isEmpty) {
              return const Center(child: Text('No history for that memory.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: revisions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final revision = revisions[i];
                // Oldest revision (last in the newest-first list) has no
                // prior point to diff against.
                final older = i + 1 < revisions.length
                    ? revisions[i + 1]
                    : null;
                return _RevisionCard(
                  revision: revision,
                  olderCommitId: older?.commit?.id,
                  memoryId: memoryId,
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                err is HvApiError ? err.error : 'Could not load history: $err',
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

class _RevisionCard extends ConsumerStatefulWidget {
  final HvMemoryRevision revision;
  final String? olderCommitId;
  final String memoryId;

  const _RevisionCard({
    required this.revision,
    required this.olderCommitId,
    required this.memoryId,
  });

  @override
  ConsumerState<_RevisionCard> createState() => _RevisionCardState();
}

class _RevisionCardState extends ConsumerState<_RevisionCard> {
  bool _showDiff = false;
  Future<HvMemoryDiffResult>? _diffFuture;

  void _toggleDiff() {
    setState(() {
      _showDiff = !_showDiff;
      if (_showDiff && _diffFuture == null) {
        final commit = widget.revision.commit;
        final older = widget.olderCommitId;
        if (commit != null && older != null) {
          _diffFuture = ref
              .read(hyperVaultMindServiceProvider)
              .diffMemory(
                from: older,
                to: commit.id,
                memoryId: widget.memoryId,
              );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revision = widget.revision;
    final commit = revision.commit;
    final canDiff = commit != null && widget.olderCommitId != null;

    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _OpBadge(op: revision.op),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  commit?.message.isNotEmpty == true
                      ? commit!.message
                      : revision.title,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              'by ${commit?.authorLabel ?? 'you'}',
              if (commit?.createdAt != null)
                DateFormat.yMMMd().add_jm().format(commit!.createdAt!),
              if (commit?.branch != null) 'branch ${commit!.branch}',
            ].join(' · '),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (canDiff) ...[
            const SizedBox(height: 8),
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: _toggleDiff,
              leading: HugeIcon(
                icon: _showDiff
                    ? HugeIcons.strokeRoundedArrowUp01
                    : HugeIcons.strokeRoundedGitCompare,
                size: 14,
              ),
              child: Text(_showDiff ? 'Hide diff' : 'Diff'),
            ),
            if (_showDiff)
              FutureBuilder<HvMemoryDiffResult>(
                future: _diffFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    final err = snapshot.error;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        err is HvApiError ? err.error : 'Could not load diff.',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  final result = snapshot.data;
                  if (result == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DiffHunkView(diff: result.diff),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _OpBadge extends StatelessWidget {
  final String op;

  const _OpBadge({required this.op});

  @override
  Widget build(BuildContext context) {
    if (op == 'delete') {
      return ShadBadge.destructive(
        child: Text(op, style: const TextStyle(fontSize: 10)),
      );
    }
    if (op == 'create') {
      return ShadBadge(child: Text(op, style: const TextStyle(fontSize: 10)));
    }
    return ShadBadge.secondary(
      child: Text(op, style: const TextStyle(fontSize: 10)),
    );
  }
}
