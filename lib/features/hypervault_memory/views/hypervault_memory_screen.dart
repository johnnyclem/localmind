import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../data/models/hv_memory_recall_result.dart';
import '../data/models/hv_memory_summary.dart';
import '../providers/hypervault_memory_providers.dart';
import 'components/memorize_sheet.dart';
import 'components/memory_browse_card.dart';
import 'components/memory_recall_card.dart';
import 'hypervault_memory_detail_screen.dart';
import 'hypervault_mind_branches_screen.dart';

/// Memory wiki home (T-M6-01 through T-M6-04): browse the active branch's
/// wiki, with instant local filtering that hands off to debounced server
/// recall as you keep typing. Threads `branch` (from
/// [hyperVaultActiveBranchProvider]) into every downstream call.
class HypervaultMemoryScreen extends ConsumerWidget {
  const HypervaultMemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final browse = ref.watch(hyperVaultMemoryBrowseProvider);
    final query = ref.watch(hyperVaultMemorySearchQueryProvider);
    final branch = ref.watch(hyperVaultActiveBranchProvider);
    final recall = ref.watch(hyperVaultMemoryRecallProvider);
    final isSearching = query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
          IconButton(
            tooltip: 'Branches',
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedGitBranch),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HypervaultMindBranchesScreen(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMemorizeSheet(context, ref),
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedBrain, size: 18),
        label: const Text('Memorize'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: browse.when(
                      data: (memories) => Text(
                        '${memories.length} ${memories.length == 1 ? 'memory' : 'memories'} in your wiki',
                        style: theme.textTheme.labelMedium,
                      ),
                      loading: () => Text(
                        'Loading your wiki…',
                        style: theme.textTheme.labelMedium,
                      ),
                      error: (_, _) => Text(
                        'Could not load your wiki',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  if (branch != null)
                    ShadBadge.secondary(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedGitBranch,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(branch, style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShadInput(
                placeholder: const Text('Search your memories…'),
                leading: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    size: 16,
                  ),
                ),
                trailing: isSearching
                    ? IconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 16,
                        ),
                        onPressed: () => ref
                            .read(hyperVaultMemorySearchQueryProvider.notifier)
                            .clear(),
                      )
                    : null,
                onChanged: (v) => ref
                    .read(hyperVaultMemorySearchQueryProvider.notifier)
                    .setQuery(v),
              ),
            ),
            if (isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _RecallStatusLine(recall: recall),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: browse.when(
                data: (memories) => _MemoryListBody(
                  memories: memories,
                  isSearching: isSearching,
                  recall: recall,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      err is HvApiError
                          ? err.error
                          : 'Could not load your wiki: $err',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecallStatusLine extends StatelessWidget {
  final HvRecallState recall;

  const _RecallStatusLine({required this.recall});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    if (recall.isRecalling) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: 6),
          Text(
            'recalling…',
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
        ],
      );
    }
    final response = recall.response;
    if (response != null) {
      final modeLabel = response.isHybrid
          ? 'semantic + keyword recall'
          : 'keyword recall';
      return Text(
        '$modeLabel · ${response.results.length} match${response.results.length == 1 ? '' : 'es'}',
        style: theme.textTheme.labelSmall?.copyWith(color: muted),
      );
    }
    if (recall.status == HvRecallStatus.error) {
      return Text(
        'Could not reach recall — showing local matches (${recall.error ?? 'error'}).',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    return Text(
      'filtering locally…',
      style: theme.textTheme.labelSmall?.copyWith(color: muted),
    );
  }
}

class _MemoryListBody extends ConsumerWidget {
  final List<HvMemorySummary> memories;
  final bool isSearching;
  final HvRecallState recall;

  const _MemoryListBody({
    required this.memories,
    required this.isSearching,
    required this.recall,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isSearching) {
      if (memories.isEmpty) return const _EmptyWikiState();
      return _BrowseList(memories: memories);
    }

    final response = recall.response;
    if (response != null) {
      if (response.results.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(response.message, textAlign: TextAlign.center),
          ),
        );
      }
      return _RecallList(results: response.results);
    }

    final local = ref.watch(hyperVaultMemoryLocalFilterProvider);
    if (local.isEmpty) {
      return const Center(child: Text('No matches yet…'));
    }
    return _BrowseList(memories: local);
  }
}

class _BrowseList extends StatelessWidget {
  final List<HvMemorySummary> memories;

  const _BrowseList({required this.memories});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: memories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final memory = memories[i];
        return MemoryBrowseCard(
          memory: memory,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HypervaultMemoryDetailScreen(memoryId: memory.id),
            ),
          ),
        );
      },
    );
  }
}

class _RecallList extends StatelessWidget {
  final List<HvMemoryRecallResult> results;

  const _RecallList({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final result = results[i];
        return MemoryRecallCard(
          result: result,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HypervaultMemoryDetailScreen(memoryId: result.id),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyWikiState extends StatelessWidget {
  const _EmptyWikiState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedBrain,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Your wiki is empty — memorize your first chunk, or let your '
              'agents do it via MCP.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
