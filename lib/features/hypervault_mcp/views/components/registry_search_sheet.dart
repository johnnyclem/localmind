import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_mcp_server.dart';
import '../../data/models/hv_registry_server.dart';
import '../../providers/hypervault_mcp_providers.dart';
import 'add_server_sheet.dart';

/// Registry search sheet (spec T-M11-05): debounced search over the public
/// MCP registry, one-tap add. A registry outage or empty result degrades to
/// a hint pointing at add-by-URL rather than blocking the flow.
Future<void> showMcpRegistrySearchSheet(BuildContext context) async {
  await showShadSheet(
    context: context,
    builder: (ctx) => const _RegistrySearchSheetContent(),
  );
}

class _RegistrySearchSheetContent extends ConsumerWidget {
  const _RegistrySearchSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(hvRegistrySearchProvider);
    final connected = (ref.watch(hvMcpConsoleProvider).value?.persisted ?? const <HvMcpServer>[])
        .map((s) => s.url)
        .toSet();

    return ShadSheet(
      title: const Text('Add from registry'),
      description: const Text('Search the public MCP registry and add a server in one tap.'),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ShadInput(
              placeholder: const Text('Search servers…'),
              leading: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 16),
              ),
              onChanged: (v) => ref.read(hvRegistrySearchProvider.notifier).setQuery(v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: searchState.result.when(
                data: (result) {
                  final list = searchState.query.trim().isEmpty ? result.suggested : result.servers;
                  if (list.isEmpty) {
                    return _EmptyRegistryHint(query: searchState.query);
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final server = list[index];
                      return _RegistryResultTile(
                        server: server,
                        alreadyConnected: connected.contains(server.url),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _EmptyRegistryHint(query: searchState.query),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRegistryHint extends StatelessWidget {
  final String query;
  const _EmptyRegistryHint({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedPackageSearch,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              query.trim().isEmpty
                  ? 'No suggested servers right now.'
                  : 'No remote-capable servers matched "$query".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You can still connect a server by pasting its URL directly.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
                showAddMcpServerSheet(context);
              },
              child: const Text('Add by URL'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistryResultTile extends ConsumerStatefulWidget {
  final HvRegistryServer server;
  final bool alreadyConnected;

  const _RegistryResultTile({required this.server, required this.alreadyConnected});

  @override
  ConsumerState<_RegistryResultTile> createState() => _RegistryResultTileState();
}

class _RegistryResultTileState extends ConsumerState<_RegistryResultTile> {
  bool _adding = false;
  bool _added = false;

  Future<void> _add() async {
    setState(() => _adding = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(hvMcpConsoleProvider.notifier)
          .addServer(
            url: widget.server.url,
            name: widget.server.name,
            registryId: widget.server.registryId,
          );
      if (!mounted) return;
      setState(() => _added = true);
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Could not add: $e')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final server = widget.server;
    final done = _added || widget.alreadyConnected;

    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        server.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        server.transport,
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
                      ),
                    ),
                    if (server.dead) ...[
                      const SizedBox(width: 6),
                      const Text('unreachable', style: TextStyle(fontSize: 10, color: Colors.orange)),
                    ],
                  ],
                ),
                if (server.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      server.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            const Text('Added', style: TextStyle(fontSize: 12))
          else
            ShadButton.outline(
              enabled: !_adding,
              onPressed: _add,
              child: _adding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
        ],
      ),
    );
  }
}
