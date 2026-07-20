import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/hv_error_toast.dart';
import '../data/models/memory.dart';
import '../providers/memory_providers.dart';
import 'components/import_sheet.dart';
import 'components/memorize_sheet.dart';
import 'components/memory_card.dart';

/// Memory screen (mobile PRD T-M6-01 through T-M6-07) — the mobile
/// counterpart of the web `/vault/memory` Search mode. Ask and Graph modes
/// are out of scope for v1 (they depend on chat/graph infrastructure not
/// yet built for mobile — see M8/M4); this screen is Search-only.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openMemorize() async {
    final message = await showMemorizeSheet(context);
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openImport() async {
    final message = await showImportMemorySheet(context);
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openDetail(String memoryId) {
    context.push(AppRoutes.memoryDetail, extra: memoryId);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(memoryListProvider);
    final search = ref.watch(memorySearchProvider);

    ref.listen<AsyncValue<List<MemoryListItem>>>(memoryListProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(error: (err, _) => showHvError(context, err));
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          listState.value != null
              ? '${listState.value!.length} memories in your wiki'
              : 'Memory',
        ),
        actions: [
          IconButton(
            tooltip: 'Git for a Mind',
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedGitBranch),
            onPressed: () => context.push(AppRoutes.gitMind),
          ),
          IconButton(
            tooltip: 'Import',
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedFileUpload),
            onPressed: _openImport,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ShadInput(
              controller: _searchController,
              placeholder: const Text('Search your memories'),
              leading: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 16,
                ),
              ),
              trailing: search.query.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ref.read(memorySearchProvider.notifier).clear();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 16,
                        ),
                      ),
                    ),
              onChanged: (value) =>
                  ref.read(memorySearchProvider.notifier).onQueryChanged(value),
            ),
          ),
          if (search.query.trim().isNotEmpty) _SearchStatusRow(search: search),
          Expanded(
            child: listState.when(
              data: (items) =>
                  _MemoryList(items: items, search: search, onTap: _openDetail),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorState(
                message: err is Exception
                    ? err.toString()
                    : 'Could not load your wiki.',
                onRetry: () => ref.read(memoryListProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMemorize,
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedNote01),
        label: const Text('Memorize'),
      ),
    );
  }
}

class _SearchStatusRow extends StatelessWidget {
  final MemorySearchState search;

  const _SearchStatusRow({required this.search});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String label;
    if (search.isSearching) {
      label = 'recalling…';
    } else if (search.error != null) {
      label = search.error!;
    } else if (search.hasFreshResponse) {
      final response = search.response!;
      final kind = response.isHybrid
          ? 'semantic + keyword recall'
          : 'keyword recall';
      final count = response.results.length;
      label = '$count match${count == 1 ? '' : 'es'} · $kind';
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: search.error != null
              ? colorScheme.error
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MemoryList extends ConsumerWidget {
  final List<MemoryListItem> items;
  final MemorySearchState search;
  final void Function(String memoryId) onTap;

  const _MemoryList({
    required this.items,
    required this.search,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = search.query.trim();
    final List<MemoryListItem> displayed;
    if (query.isEmpty) {
      displayed = items;
    } else if (search.hasFreshResponse) {
      displayed = search.response!.results;
    } else {
      displayed = filterMemoriesLocally(items, query);
    }

    if (items.isEmpty && query.isEmpty) {
      return const _EmptyState();
    }

    if (displayed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Nothing matches "$query" yet.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(memoryListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: displayed.length,
        itemBuilder: (context, index) {
          final memory = displayed[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MemoryCard(memory: memory, onTap: () => onTap(memory.id)),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedBookOpen01,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 20),
            Text(
              'No memories yet — memorize something to get started.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
