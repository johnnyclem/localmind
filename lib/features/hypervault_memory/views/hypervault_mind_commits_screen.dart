import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../providers/hypervault_memory_providers.dart';

/// `git log` for a branch (T-M7-10): short hash, message, author, date, and
/// per-commit change counts.
class HypervaultMindCommitsScreen extends ConsumerWidget {
  final String? branch;
  final String branchLabel;

  const HypervaultMindCommitsScreen({
    super.key,
    required this.branch,
    required this.branchLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final commitsAsync = ref.watch(hyperVaultMindCommitsProvider(branch));

    return Scaffold(
      appBar: AppBar(title: Text('Commits — $branchLabel')),
      body: SafeArea(
        child: commitsAsync.when(
          data: (commits) {
            if (commits.isEmpty) {
              return const Center(
                child: Text('No commits on this branch yet.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: commits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final commit = commits[i];
                return ShadCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            commit.shortId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              commit.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            [
                              'by ${commit.authorLabel}',
                              if (commit.createdAt != null)
                                DateFormat.yMMMd().add_jm().format(
                                  commit.createdAt!,
                                ),
                            ].join(' · '),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (commit.changeCounts.created > 0)
                            _CountChip(
                              label: '+${commit.changeCounts.created}',
                              color: Colors.green,
                            ),
                          if (commit.changeCounts.updated > 0)
                            _CountChip(
                              label: '~${commit.changeCounts.updated}',
                              color: Colors.orange,
                            ),
                          if (commit.changeCounts.deleted > 0)
                            _CountChip(
                              label: '-${commit.changeCounts.deleted}',
                              color: Colors.red,
                            ),
                        ],
                      ),
                    ],
                  ),
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
                err is HvApiError ? err.error : 'Could not load the log: $err',
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

class _CountChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CountChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
