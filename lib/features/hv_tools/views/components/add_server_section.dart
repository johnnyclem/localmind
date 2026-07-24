import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../../../core/providers/hypervault_providers.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/registry_entry.dart';
import '../../providers/hv_tools_providers.dart';

class _HeaderFieldPair {
  final key = TextEditingController();
  final value = TextEditingController();

  void dispose() {
    key.dispose();
    value.dispose();
  }
}

/// Add-by-URL form (with optional name + repeatable auth header rows) and a
/// debounced registry search box beneath it, per T-M11-04/05.
class AddServerSection extends ConsumerStatefulWidget {
  const AddServerSection({super.key});

  @override
  ConsumerState<AddServerSection> createState() => _AddServerSectionState();
}

class _AddServerSectionState extends ConsumerState<AddServerSection> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final List<_HeaderFieldPair> _headers = [];
  Timer? _debounce;
  bool _submitting = false;
  String? _addingRegistryId;
  final Set<String> _justAdded = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(registrySearchProvider.notifier).loadSuggested(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _urlController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    for (final h in _headers) {
      h.dispose();
    }
    super.dispose();
  }

  int get _maxServers =>
      ref.read(capabilitiesProvider).value?.limits.maxMcpServers ?? 20;

  void _addHeaderRow() {
    setState(() => _headers.add(_HeaderFieldPair()));
  }

  void _removeHeaderRow(_HeaderFieldPair pair) {
    setState(() => _headers.remove(pair));
    pair.dispose();
  }

  bool get _isValidUrl {
    final url = _urlController.text.trim();
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Future<void> _submit() async {
    if (!_isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid http(s) URL.')),
      );
      return;
    }
    final headers = <String, String>{};
    for (final h in _headers) {
      final key = h.key.text.trim();
      final value = h.value.text;
      if (key.isNotEmpty && value.isNotEmpty) headers[key] = value;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(hvToolsProvider.notifier)
          .addServer(
            url: _urlController.text.trim(),
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
            headers: headers.isEmpty ? null : headers,
            maxServers: _maxServers,
          );
      if (mounted) {
        _urlController.clear();
        _nameController.clear();
        for (final h in _headers) {
          h.dispose();
        }
        setState(() => _headers.clear());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Server connected.')));
      }
    } catch (e) {
      _showError(e, 'Failed to connect that server.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(registrySearchProvider.notifier).search(value);
    });
  }

  Future<void> _addFromRegistry(RegistryServerEntry entry) async {
    if (entry.url == null || entry.registryId == null) return;
    setState(() => _addingRegistryId = entry.registryId);
    try {
      await ref
          .read(hvToolsProvider.notifier)
          .addServerFromRegistry(
            url: entry.url!,
            name: entry.name,
            registryId: entry.registryId!,
            maxServers: _maxServers,
          );
      if (mounted) setState(() => _justAdded.add(entry.registryId!));
    } catch (e) {
      _showError(e, 'Failed to connect that server.');
    } finally {
      if (mounted) setState(() => _addingRegistryId = null);
    }
  }

  void _showError(Object e, String fallback) {
    if (!mounted) return;
    final message = e is HyperVaultApiException ? e.message : fallback;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(registrySearchProvider);
    final connectedUrls =
        (ref.watch(hvToolsProvider).value?.persisted ?? const [])
            .map((s) => s.url.trim().toLowerCase())
            .toSet();
    final results = searchState.query.isEmpty
        ? searchState.suggested
        : searchState.servers;

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add server', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ShadInput(
            controller: _urlController,
            placeholder: const Text('https://example.com/mcp'),
          ),
          const SizedBox(height: 8),
          ShadInput(
            controller: _nameController,
            placeholder: const Text('Name (optional)'),
          ),
          const SizedBox(height: 8),
          for (final pair in _headers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: pair.key,
                      placeholder: const Text('Header name'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ShadInput(
                      controller: pair.value,
                      placeholder: const Text('Header value'),
                      obscureText: true,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove header',
                    onPressed: () => _removeHeaderRow(pair),
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addHeaderRow,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 16,
              ),
              label: const Text('Add auth header'),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton(
              onPressed: _submitting ? null : _submit,
              leading: _submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              child: const Text('Connect server'),
            ),
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Search the registry',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.mcpRegistry),
                child: const Text('Browse full registry'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ShadInput(
            controller: _searchController,
            placeholder: const Text('Search MCP servers…'),
            leading: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 16),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          if (searchState.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (searchState.error != null)
            Text(
              searchState.error!,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
            )
          else if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                searchState.query.isEmpty
                    ? 'No suggested servers right now.'
                    : 'No remote-capable matches. Try adding by URL above.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else
            for (final entry in results)
              _RegistryResultTile(
                entry: entry,
                alreadyConnected:
                    entry.url != null &&
                    connectedUrls.contains(entry.url!.trim().toLowerCase()),
                added:
                    entry.registryId != null &&
                    _justAdded.contains(entry.registryId),
                busy:
                    entry.registryId != null &&
                    _addingRegistryId == entry.registryId,
                onAdd: () => _addFromRegistry(entry),
              ),
        ],
      ),
    );
  }
}

class _RegistryResultTile extends StatelessWidget {
  final RegistryServerEntry entry;
  final bool alreadyConnected;
  final bool added;
  final bool busy;
  final VoidCallback onAdd;

  const _RegistryResultTile({
    required this.entry,
    required this.alreadyConnected,
    required this.added,
    required this.busy,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdded = alreadyConnected || added;
    final canAdd =
        !isAdded && !busy && entry.url != null && entry.registryId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.transport != null) ...[
                      const SizedBox(width: 6),
                      ShadBadge.secondary(child: Text(entry.transport!)),
                    ],
                  ],
                ),
                if ((entry.description ?? '').isNotEmpty)
                  Text(
                    entry.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ShadButton.outline(
            onPressed: canAdd ? onAdd : null,
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isAdded ? 'Added' : 'Add'),
          ),
        ],
      ),
    );
  }
}
