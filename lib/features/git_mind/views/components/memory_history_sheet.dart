import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../../memory/providers/memory_providers.dart';
import '../../data/models/git_mind_models.dart';
import '../../providers/git_mind_providers.dart';

/// Relative timestamp, mirroring
/// `lib/features/memory/views/components/memory_card.dart`'s helper — kept
/// as a local copy so this feature has no dependency on the sibling memory
/// feature's file layout beyond the provider it reuses.
String _formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

String _authorLabel(RevisionCommitInfo? commit) {
  if (commit == null) return '';
  switch (commit.authorKind) {
    case 'user':
      return 'you';
    case 'agent':
      final prefix = commit.authorKeyPrefix;
      return prefix == null || prefix.isEmpty ? 'agent' : 'agent $prefix';
    case 'system':
      return 'system';
    default:
      return commit.authorKind;
  }
}

/// History/diff sheet (T-M7-06/07/08) — a timeline of a memory's revisions.
/// Tapping a revision expands a side-by-side snapshot of that version vs.
/// the current memory (title/tags/content), plus a "Restore this version"
/// action (`POST /api/mind/revert`). Reusable: any screen with a memory id
/// can open it via [showMemoryHistorySheet].
Future<void> showMemoryHistorySheet(
  BuildContext context, {
  required String memoryId,
  required String currentTitle,
  required String currentContent,
  required List<String> currentTags,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _MemoryHistorySheet(
      memoryId: memoryId,
      currentTitle: currentTitle,
      currentContent: currentContent,
      currentTags: currentTags,
    ),
  );
}

class _MemoryHistorySheet extends ConsumerStatefulWidget {
  final String memoryId;
  final String currentTitle;
  final String currentContent;
  final List<String> currentTags;

  const _MemoryHistorySheet({
    required this.memoryId,
    required this.currentTitle,
    required this.currentContent,
    required this.currentTags,
  });

  @override
  ConsumerState<_MemoryHistorySheet> createState() =>
      _MemoryHistorySheetState();
}

class _MemoryHistorySheetState extends ConsumerState<_MemoryHistorySheet> {
  String? _expandedRevisionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(memoryHistoryProvider(widget.memoryId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedGitCommit, size: 20),
                  const SizedBox(width: 8),
                  Text('History', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: historyAsync.when(
                  data: (history) => history.revisions.isEmpty
                      ? const Center(child: Text('No history yet.'))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: history.revisions.length,
                          itemBuilder: (context, index) {
                            final revision = history.revisions[index];
                            final expanded =
                                _expandedRevisionId == revision.revisionId;
                            return _RevisionTile(
                              memoryId: widget.memoryId,
                              revision: revision,
                              expanded: expanded,
                              currentTitle: widget.currentTitle,
                              currentContent: widget.currentContent,
                              currentTags: widget.currentTags,
                              isLatest: index == 0,
                              onTap: () => setState(() {
                                _expandedRevisionId = expanded
                                    ? null
                                    : revision.revisionId;
                              }),
                            );
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            err is HyperVaultApiException
                                ? err.message
                                : 'Could not load history.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => ref
                                .read(
                                  memoryHistoryProvider(
                                    widget.memoryId,
                                  ).notifier,
                                )
                                .refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RevisionTile extends ConsumerStatefulWidget {
  final String memoryId;
  final MemoryRevision revision;
  final bool expanded;
  final bool isLatest;
  final String currentTitle;
  final String currentContent;
  final List<String> currentTags;
  final VoidCallback onTap;

  const _RevisionTile({
    required this.memoryId,
    required this.revision,
    required this.expanded,
    required this.isLatest,
    required this.currentTitle,
    required this.currentContent,
    required this.currentTags,
    required this.onTap,
  });

  @override
  ConsumerState<_RevisionTile> createState() => _RevisionTileState();
}

class _RevisionTileState extends ConsumerState<_RevisionTile> {
  bool _restoring = false;
  String? _restoreError;

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore this version?'),
        content: Text(
          '"${widget.revision.title}" will be restored as a new commit. '
          'The current version stays in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _restoring = true;
      _restoreError = null;
    });

    try {
      final result = await ref
          .read(gitMindApiServiceProvider)
          .revert(
            memoryId: widget.memoryId,
            revisionId: widget.revision.revisionId,
          );
      unawaited(
        ref.read(memoryHistoryProvider(widget.memoryId).notifier).refresh(),
      );
      unawaited(
        ref.read(memoryDetailProvider(widget.memoryId).notifier).refresh(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } on HyperVaultApiException catch (e) {
      if (mounted) {
        setState(() {
          _restoring = false;
          _restoreError = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _restoring = false;
          _restoreError = 'Could not restore — check your connection.';
        });
      }
    }
  }

  Widget _opBadge(ThemeData theme) {
    final revision = widget.revision;
    if (revision.isDelete) {
      return const ShadBadge.destructive(child: Text('deleted'));
    }
    if (revision.isCreate) {
      return const ShadBadge(child: Text('created'));
    }
    return const ShadBadge.secondary(child: Text('updated'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revision = widget.revision;
    final commit = revision.commit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _opBadge(theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (commit?.message.isNotEmpty ?? false)
                              ? commit!.message
                              : revision.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (commit != null) ...[
                              Text(
                                _authorLabel(commit),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatRelativeTime(commit.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              if (commit.branch != 'main') ...[
                                const SizedBox(width: 8),
                                ShadBadge.outline(child: Text(commit.branch)),
                              ],
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  HugeIcon(
                    icon: widget.expanded
                        ? HugeIcons.strokeRoundedArrowUp01
                        : HugeIcons.strokeRoundedArrowDown01,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
            if (widget.expanded) ...[
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SnapshotColumn(
                      label: 'This revision',
                      title: revision.title,
                      content: revision.content,
                      tags: revision.tags,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SnapshotColumn(
                      label: 'Current',
                      title: widget.currentTitle,
                      content: widget.currentContent,
                      tags: widget.currentTags,
                    ),
                  ),
                ],
              ),
              if (_restoreError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _restoreError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              if (!widget.isLatest && !revision.isDelete) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ShadButton.outline(
                    onPressed: _restoring ? null : _restore,
                    child: _restoring
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Restore this version'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SnapshotColumn extends StatelessWidget {
  final String label;
  final String title;
  final String? content;
  final List<String> tags;

  const _SnapshotColumn({
    required this.label,
    required this.title,
    this.content,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (content != null && content!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              content!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: tags
                  .take(4)
                  .map(
                    (t) => Text(
                      '#$t',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

void unawaited(Future<void> future) {}
