import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../data/models/git_mind_models.dart';
import '../providers/git_mind_providers.dart';
import 'components/create_branch_sheet.dart';
import 'components/merge_sheet.dart';
import 'components/mind_state_sheet.dart';

/// Coarse, human-friendly relative timestamp — a local copy of the same
/// helper used by `lib/features/memory/views/components/memory_card.dart`,
/// kept local so this feature doesn't reach into the sibling memory
/// feature's file layout.
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

/// Git-mind screen (mobile PRD M7) — branch switcher, create/delete branch,
/// merge (with conflict resolution), and the commit log for the currently
/// checked-out branch. Reachable at `AppRoutes.gitMind`.
class GitMindScreen extends ConsumerWidget {
  const GitMindScreen({super.key});

  Future<void> _createBranch(
    BuildContext context,
    WidgetRef ref,
    String fromBranch,
  ) async {
    final result = await showCreateBranchSheet(context, fromBranch: fromBranch);
    if (result == null) return;
    ref.read(selectedGitMindBranchProvider.notifier).set(result.name);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _deleteBranch(
    BuildContext context,
    WidgetRef ref,
    MindBranch branch,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this branch?'),
        content: Text(
          '"${branch.name}" and its commit history will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final message = await ref
          .read(gitMindApiServiceProvider)
          .deleteBranch(branch.name);
      ref.read(selectedGitMindBranchProvider.notifier).set('main');
      unawaited(ref.read(mindBranchesProvider.notifier).refresh());
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } on HyperVaultApiException catch (e) {
      // e.g. 400 default-branch / 409 has-children — show verbatim.
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete that branch.')),
        );
      }
    }
  }

  Future<void> _openMerge(
    BuildContext context,
    WidgetRef ref,
    List<MindBranch> branches,
    String targetBranch,
  ) async {
    final result = await showMergeSheet(
      context,
      targetBranch: targetBranch,
      branches: branches,
    );
    if (result == null) return;
    unawaited(ref.read(mindBranchesProvider.notifier).refresh());
    unawaited(ref.read(mindCommitsProvider(targetBranch).notifier).refresh());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.message} (${result.merged.created} created, '
            '${result.merged.updated} updated, ${result.merged.deleted} deleted, '
            '${result.linksChanged} links changed)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final branchesAsync = ref.watch(mindBranchesProvider);
    final selectedBranch = ref.watch(selectedGitMindBranchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Git for a Mind')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(mindBranchesProvider.notifier).refresh();
          await ref
              .read(mindCommitsProvider(selectedBranch).notifier)
              .refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            branchesAsync.when(
              data: (branches) {
                final effectiveBranches = branches.isEmpty
                    ? const [
                        MindBranch(
                          id: 'main',
                          name: 'main',
                          isDefault: true,
                          memoryCount: 0,
                        ),
                      ]
                    : branches;
                final current = effectiveBranches.firstWhere(
                  (b) => b.name == selectedBranch,
                  orElse: () => effectiveBranches.first,
                );
                return _BranchSwitcher(
                  branches: effectiveBranches,
                  selected: selectedBranch,
                  onSelect: (name) => ref
                      .read(selectedGitMindBranchProvider.notifier)
                      .set(name),
                  onCreate: () => _createBranch(context, ref, selectedBranch),
                  onDelete: current.isDefault
                      ? null
                      : () => _deleteBranch(context, ref, current),
                  onMerge: () => _openMerge(
                    context,
                    ref,
                    effectiveBranches,
                    selectedBranch,
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      err is HyperVaultApiException
                          ? err.message
                          : 'Could not load branches.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(mindBranchesProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Latest commits on $selectedBranch', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final commitsAsync = ref.watch(
                  mindCommitsProvider(selectedBranch),
                );
                return commitsAsync.when(
                  data: (log) => log.commits.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No commits yet on "$selectedBranch".',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        )
                      : Column(
                          children: log.commits
                              .map(
                                (commit) => _CommitRow(
                                  commit: commit,
                                  branch: selectedBranch,
                                ),
                              )
                              .toList(),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          err is HyperVaultApiException
                              ? err.message
                              : 'Could not load commits.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref
                              .read(
                                mindCommitsProvider(selectedBranch).notifier,
                              )
                              .refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchSwitcher extends StatelessWidget {
  final List<MindBranch> branches;
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final VoidCallback? onDelete;
  final VoidCallback onMerge;

  const _BranchSwitcher({
    required this.branches,
    required this.selected,
    required this.onSelect,
    required this.onCreate,
    required this.onDelete,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Branches', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...branches.map(
                (branch) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${branch.name} [${branch.memoryCount}]'),
                    selected: branch.name == selected,
                    showCheckmark: false,
                    onSelected: (_) => onSelect(branch.name),
                  ),
                ),
              ),
              ActionChip(
                avatar: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlusSignCircle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                label: const Text('New branch'),
                onPressed: onCreate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ShadButton.outline(
                onPressed: onMerge,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedGitMerge,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text('Merge'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: onDelete == null
                  ? "Can't delete the default branch"
                  : 'Delete branch',
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
              color: onDelete == null ? theme.colorScheme.outline : Colors.red,
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    );
  }
}

class _CommitRow extends ConsumerWidget {
  final MindCommit commit;
  final String branch;

  const _CommitRow({required this.commit, required this.branch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final counts = commit.changeCounts;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HugeIcon(
              icon: commit.isMerge
                  ? HugeIcons.strokeRoundedGitPullRequest
                  : HugeIcons.strokeRoundedGitCommit,
              size: 18,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commit.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        commit.authorKind,
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
                    ],
                  ),
                  if (counts.total > 0 || counts.links > 0) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (counts.created > 0)
                          ShadBadge(child: Text('+${counts.created}')),
                        if (counts.updated > 0)
                          ShadBadge.secondary(
                            child: Text('~${counts.updated}'),
                          ),
                        if (counts.deleted > 0)
                          ShadBadge.destructive(
                            child: Text('-${counts.deleted}'),
                          ),
                        if (counts.links > 0)
                          ShadBadge.outline(
                            child: Text('${counts.links} links'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'View as of this commit',
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedTime04, size: 18),
              onPressed: () => showMindStateSheet(
                context,
                at: commit.id,
                branch: branch,
                label: commit.shortId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {}
