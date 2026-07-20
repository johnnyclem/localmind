import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../data/models/mcp_server_entry.dart';
import '../providers/hv_tools_providers.dart';
import 'components/add_server_section.dart';
import 'components/compile_footer.dart';
import 'components/server_blade.dart';
import 'components/toolkit_status_header.dart';

/// HyperVault's server-side MCP & Tools console (`/hv-tools`, PRD M11).
///
/// Distinct from lib/features/mcp/, which manages MCP servers the on-device
/// chat connects to directly. This screen manages the servers HyperVault's
/// backend introspects and compiles into a shared toolkit consumed by
/// `POST /api/chat`'s `use_tools` flag.
///
/// Mirrors the web console's draft/compile model: toggling a server or a
/// tool only edits local draft state (see [HvToolsNotifier]); nothing
/// reaches the API until "Compile Tools" is tapped.
class McpToolsConsoleScreen extends ConsumerWidget {
  const McpToolsConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(hvToolsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: asyncState.when(
        data: (state) => _ToolsConsoleBody(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  size: 40,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  err is HyperVaultApiException ? err.message : err.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(hvToolsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: asyncState.hasValue ? const CompileFooter() : null,
    );
  }
}

class _ToolsConsoleBody extends ConsumerWidget {
  final HvToolsState state;

  const _ToolsConsoleBody({required this.state});

  bool _entryDirty(McpServerEntry draftEntry) {
    McpServerEntry? persisted;
    for (final p in state.persisted) {
      if (p.id == draftEntry.id) {
        persisted = p;
        break;
      }
    }
    if (persisted == null) return false;
    if (persisted.enabled != draftEntry.enabled) return true;
    final a = persisted.disabledTools.toSet();
    final b = draftEntry.disabledTools.toSet();
    return a.length != b.length || !a.containsAll(b);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(hvToolsProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ToolkitStatusHeader(toolkit: state.toolkit, isDirty: state.isDirty),
          const SizedBox(height: 16),
          if (state.draft.isEmpty)
            _EmptyState(theme: theme)
          else ...[
            Text('Connected servers', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final entry in state.draft)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ServerBlade(
                  entry: entry,
                  isDirty: _entryDirty(entry),
                  onToggleEnabled: (value) =>
                      notifier.toggleServerEnabled(entry.id, value),
                  onToggleTool: (name, disabled) =>
                      notifier.toggleToolDisabled(entry.id, name, disabled),
                  onEnableAll: () => notifier.enableAllTools(entry.id),
                  onDisableAll: () => notifier.disableAllTools(entry.id),
                  onRefresh: () => notifier.refreshServer(entry.id),
                  onDelete: () => notifier.deleteServer(entry.id),
                ),
              ),
          ],
          const SizedBox(height: 16),
          const AddServerSection(),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedServerStack01,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('No MCP servers connected yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Search the registry or add one by URL below to give chat '
            'access to its tools.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
