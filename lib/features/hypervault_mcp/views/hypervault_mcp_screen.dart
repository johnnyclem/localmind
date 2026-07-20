import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../data/models/hv_mcp_compile_outcome.dart';
import '../data/models/hv_mcp_server.dart';
import '../providers/hv_mcp_console_state.dart';
import '../providers/hypervault_mcp_providers.dart';
import 'components/add_server_sheet.dart';
import 'components/compile_result_sheet.dart';
import 'components/mcp_server_blade.dart';
import 'components/registry_search_sheet.dart';
import 'components/server_edit_dialogs.dart';
import 'components/toolkit_status_header.dart';

/// MCP & tools console — connected servers, add/search, per-server and
/// per-tool draft toggles, and Compile/Undo (spec docs/mobile/prd/11-mcp-tools.md).
/// Tool dispatch itself stays server-side; this is management UI only.
class HyperVaultMcpScreen extends ConsumerStatefulWidget {
  const HyperVaultMcpScreen({super.key});

  @override
  ConsumerState<HyperVaultMcpScreen> createState() => _HyperVaultMcpScreenState();
}

class _HyperVaultMcpScreenState extends ConsumerState<HyperVaultMcpScreen> {
  final Set<String> _refreshingIds = {};
  bool _compiling = false;

  Future<void> _pullToRefresh() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Future.wait([
        ref.read(hvMcpConsoleProvider.notifier).refresh(),
        ref.read(hvToolkitStatusProvider.notifier).refresh(),
      ]);
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not refresh: $e')));
    }
  }

  Future<void> _refreshServer(HvMcpServer server) async {
    setState(() => _refreshingIds.add(server.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(hvMcpConsoleProvider.notifier).refreshServerTools(server.id);
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } finally {
      if (mounted) setState(() => _refreshingIds.remove(server.id));
    }
  }

  Future<void> _deleteServer(HvMcpServer server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${server.name}?'),
        content: const Text(
          'Compiled toolkits keep working until you compile again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(hvMcpConsoleProvider.notifier).removeServer(server.id);
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    }
  }

  Future<void> _compile() async {
    setState(() => _compiling = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await ref.read(hvMcpConsoleProvider.notifier).compile();
      if (!mounted) return;
      await showCompileResultSheet(context, outcome);
    } on HvCompileError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Compile failed: $e')));
    } finally {
      if (mounted) setState(() => _compiling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consoleAsync = ref.watch(hvMcpConsoleProvider);
    final toolkitAsync = ref.watch(hvToolkitStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Tools'),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
            tooltip: 'Search registry',
            onPressed: () => showMcpRegistrySearchSheet(context),
          ),
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlusSign),
            tooltip: 'Add server by URL',
            onPressed: () => showAddMcpServerSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: consoleAsync.when(
          data: (state) => Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _pullToRefresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      toolkitAsync.when(
                        data: (status) => ToolkitStatusHeader(status: status),
                        loading: () => const _ToolkitHeaderPlaceholder(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
                      if (state.draft.isEmpty)
                        _EmptyState(
                          onAddByUrl: () => showAddMcpServerSheet(context),
                          onSearch: () => showMcpRegistrySearchSheet(context),
                        )
                      else
                        for (final draft in state.draft)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: McpServerBlade(
                              persisted: state.persisted.firstWhere(
                                (s) => s.id == draft.id,
                                orElse: () => draft,
                              ),
                              draft: draft,
                              refreshing: _refreshingIds.contains(draft.id),
                              onToggleEnabled: (_) => ref
                                  .read(hvMcpConsoleProvider.notifier)
                                  .toggleServerEnabled(draft.id),
                              onToggleTool: (tool) => ref
                                  .read(hvMcpConsoleProvider.notifier)
                                  .toggleTool(draft.id, tool),
                              onSetAllTools: (enabled) => ref
                                  .read(hvMcpConsoleProvider.notifier)
                                  .setAllTools(draft.id, enabled: enabled),
                              onRefresh: () => _refreshServer(draft),
                              onRename: () => showRenameServerDialog(context, ref, draft),
                              onEditHeaders: () => showEditHeadersDialog(context, ref, draft),
                              onDelete: () => _deleteServer(draft),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              _CompileFooter(
                state: state,
                compiling: _compiling,
                onCompile: _compile,
                onUndo: () => ref.read(hvMcpConsoleProvider.notifier).undo(),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    color: theme.colorScheme.error,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    err is HvApiError ? err.error : 'Could not load MCP servers.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ShadButton.outline(
                    onPressed: () => ref.invalidate(hvMcpConsoleProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompileFooter extends StatelessWidget {
  final HvMcpConsoleState state;
  final bool compiling;
  final VoidCallback onCompile;
  final VoidCallback onUndo;

  const _CompileFooter({
    required this.state,
    required this.compiling,
    required this.onCompile,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dirty = state.dirty;
    final anyToolsEnabled = state.draft.any((s) => s.enabled && s.enabledToolCount > 0);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (dirty)
                Expanded(
                  child: Text(
                    '${state.pendingChangeCount} change${state.pendingChangeCount == 1 ? '' : 's'} pending',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                )
              else
                const Spacer(),
              ShadButton.outline(
                enabled: dirty && !compiling,
                onPressed: onUndo,
                child: const Text('Undo'),
              ),
              const SizedBox(width: 8),
              ShadButton(
                enabled: !compiling && anyToolsEnabled,
                leading: compiling
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onPressed: onCompile,
                child: Text(compiling ? 'Compiling… (up to 5 min)' : 'Compile Tools'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolkitHeaderPlaceholder extends StatelessWidget {
  const _ToolkitHeaderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text('Loading toolkit status…', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddByUrl;
  final VoidCallback onSearch;

  const _EmptyState({required this.onAddByUrl, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedServerStack02, size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No MCP servers connected', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Connect a server to give chat access to its tools.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadButton.outline(onPressed: onSearch, child: const Text('Search registry')),
              const SizedBox(width: 10),
              ShadButton(onPressed: onAddByUrl, child: const Text('Add by URL')),
            ],
          ),
        ],
      ),
    );
  }
}
