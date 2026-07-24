import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../chat/providers/chat_mcp_providers.dart';
import '../../hv_tools/providers/hv_tools_providers.dart';
import '../data/models/mcp_registry_server.dart';
import '../providers/mcp_registry_providers.dart';

/// Browse-and-one-click-install page for the GitHub MCP Registry
/// (https://registry.modelcontextprotocol.io, the API backing
/// github.com/mcp). Results load a page at a time via the registry's cursor
/// pagination ("Load more" below the list); tapping "Install" on a server
/// routes it automatically — on-device chat, HyperVault's server-side
/// toolkit, or (for local/stdio-only servers, which this mobile app can't
/// run) a disabled "Needs desktop" state — see
/// [McpRegistryInstallService.install].
class McpRegistryScreen extends ConsumerStatefulWidget {
  const McpRegistryScreen({super.key});

  @override
  ConsumerState<McpRegistryScreen> createState() => _McpRegistryScreenState();
}

class _McpRegistryScreenState extends ConsumerState<McpRegistryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(mcpRegistryBrowseProvider.notifier).loadInitial(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(mcpRegistryBrowseProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mcpRegistryBrowseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GitHub MCP Registry')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(mcpRegistryBrowseProvider.notifier).search(state.query),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ShadInput(
              controller: _searchController,
              placeholder: const Text('Search MCP servers…'),
              leading: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 16),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (state.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null)
              _ErrorPanel(
                message: state.error!,
                onRetry: () => ref
                    .read(mcpRegistryBrowseProvider.notifier)
                    .search(state.query),
              )
            else if (state.servers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No servers found.')),
              )
            else ...[
              for (final server in state.servers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RegistryServerTile(server: server),
                ),
              if (state.nextCursor != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: state.loadingMore
                        ? const CircularProgressIndicator()
                        : ShadButton.outline(
                            onPressed: () => ref
                                .read(mcpRegistryBrowseProvider.notifier)
                                .loadMore(),
                            child: const Text('Load more'),
                          ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            size: 32,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ShadButton.outline(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _RegistryServerTile extends ConsumerStatefulWidget {
  final McpRegistryServer server;
  const _RegistryServerTile({required this.server});

  @override
  ConsumerState<_RegistryServerTile> createState() =>
      _RegistryServerTileState();
}

class _RegistryServerTileState extends ConsumerState<_RegistryServerTile> {
  bool _busy = false;

  bool get _installedOnDevice {
    // Watching the state (not `.notifier`) is what makes this rebuild when
    // another tile's install/uninstall — or the saved-servers auto-reconnect
    // on app start — changes the shared config.
    ref.watch(chatMcpConfigProvider);
    return ref
        .read(chatMcpConfigProvider.notifier)
        .isInstalled(widget.server.displayName);
  }

  bool get _installedOnHyperVault {
    final remote = widget.server.primaryRemote;
    if (remote == null) return false;
    final persisted = ref.watch(hvToolsProvider).value?.persisted ?? const [];
    return persisted.any(
      (s) => s.url.trim().toLowerCase() == remote.url.trim().toLowerCase(),
    );
  }

  Future<Map<String, String>?> _promptForHeaders(
    List<McpRegistryVariable> headers,
  ) async {
    final controllers = {
      for (final h in headers) h.name: TextEditingController(text: h.defaultValue ?? ''),
    };
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect ${widget.server.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final h in headers) ...[
                Text(
                  h.description?.isNotEmpty == true ? h.description! : h.name,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controllers[h.name],
                  obscureText: h.isSecret,
                  decoration: InputDecoration(
                    labelText: h.name + (h.isRequired ? ' *' : ''),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final values = {
                for (final entry in controllers.entries)
                  entry.key: entry.value.text.trim(),
              };
              Navigator.pop(ctx, values);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    for (final c in controllers.values) {
      c.dispose();
    }
    return result;
  }

  Future<void> _install() async {
    final server = widget.server;
    final remote = server.primaryRemote;
    if (remote == null) return;

    Map<String, String> headerValues = const {};
    if (remote.hasDeclaredSecretHeaders) {
      final entered = await _promptForHeaders(remote.headers);
      if (entered == null) return; // cancelled
      headerValues = entered;
    }

    setState(() => _busy = true);
    try {
      final result = await ref
          .read(mcpRegistryInstallServiceProvider)
          .install(server, headerValues: headerValues);
      if (!mounted) return;
      final message = result.target == McpRegistryInstallTarget.onDevice
          ? '${server.displayName} added to on-device chat tools.'
          : '${server.displayName} added to your HyperVault toolkit.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      final message = e is McpRegistryInstallException
          ? e.message
          : e is HyperVaultApiException
              ? e.message
              : 'Could not connect to ${server.displayName}.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uninstall() async {
    setState(() => _busy = true);
    try {
      if (_installedOnDevice) {
        await ref
            .read(chatMcpConfigProvider.notifier)
            .uninstallIntegration(widget.server.displayName);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final server = widget.server;
    final needsDesktop = server.hasStdioOnly;
    final installed = _installedOnDevice || _installedOnHyperVault;

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (server.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        server.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _InstallButton(
                installed: installed,
                needsDesktop: needsDesktop,
                busy: _busy,
                onInstall: _install,
                onRemove: _installedOnDevice ? _uninstall : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final remote in server.remotes)
                ShadBadge.secondary(child: Text(remote.type)),
              if (needsDesktop)
                const ShadBadge.outline(child: Text('stdio (local)')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstallButton extends StatelessWidget {
  final bool installed;
  final bool needsDesktop;
  final bool busy;
  final VoidCallback onInstall;
  final VoidCallback? onRemove;

  const _InstallButton({
    required this.installed,
    required this.needsDesktop,
    required this.busy,
    required this.onInstall,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (needsDesktop) {
      return Tooltip(
        message:
            'Runs locally via stdio — not supported on iOS/Android yet. '
            'Needs a desktop or self-hosted companion to run this process.',
        child: ShadButton.outline(
          onPressed: null,
          child: const Text('Needs desktop'),
        ),
      );
    }
    if (busy) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (installed) {
      return ShadButton.outline(
        onPressed: onRemove,
        child: const Text('Installed'),
      );
    }
    return ShadButton(onPressed: onInstall, child: const Text('Install'));
  }
}
