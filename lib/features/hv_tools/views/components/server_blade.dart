import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../data/models/mcp_server_entry.dart';

/// One connected MCP server, rendered as an expandable "blade": master
/// enabled switch, tool count, refresh/delete actions, and (expanded) a
/// per-tool switch list. All toggles here mutate local draft state only —
/// nothing reaches the API until the console's Compile Tools action runs.
class ServerBlade extends StatefulWidget {
  final McpServerEntry entry;
  final bool isDirty;
  final ValueChanged<bool> onToggleEnabled;
  final void Function(String toolName, bool disabled) onToggleTool;
  final VoidCallback onEnableAll;
  final VoidCallback onDisableAll;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onDelete;

  const ServerBlade({
    super.key,
    required this.entry,
    required this.isDirty,
    required this.onToggleEnabled,
    required this.onToggleTool,
    required this.onEnableAll,
    required this.onDisableAll,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  State<ServerBlade> createState() => _ServerBladeState();
}

class _ServerBladeState extends State<ServerBlade> {
  bool _expanded = false;
  bool _refreshing = false;
  bool _deleting = false;

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
    } catch (e) {
      _showError(e, 'Failed to refresh this server.');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${widget.entry.name}?'),
        content: const Text(
          'Compiled toolkits keep working until you compile again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete();
    } catch (e) {
      _showError(e, 'Failed to remove this server.');
    } finally {
      if (mounted) setState(() => _deleting = false);
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
    final entry = widget.entry;
    final theme = Theme.of(context);
    final total = entry.tools.length;
    final countLabel = !entry.enabled
        ? 'off'
        : '${entry.enabledToolCount}/$total';

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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.name.isEmpty ? entry.url : entry.name,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.hasAuth) ...[
                          const SizedBox(width: 6),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedKey01,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                        if (widget.isDirty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.url,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ShadBadge.secondary(child: Text(countLabel)),
              const SizedBox(width: 8),
              ShadSwitch(
                value: entry.enabled,
                onChanged: widget.onToggleEnabled,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: total == 0
                    ? null
                    : () => setState(() => _expanded = !_expanded),
                icon: HugeIcon(
                  icon: _expanded
                      ? HugeIcons.strokeRoundedArrowUp01
                      : HugeIcons.strokeRoundedArrowDown01,
                  size: 16,
                ),
                label: Text(
                  _expanded
                      ? 'Hide tools'
                      : 'Show $total tool${total == 1 ? '' : 's'}',
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh tools',
                onPressed: _refreshing ? null : _handleRefresh,
                icon: _refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
              ),
              IconButton(
                tooltip: 'Remove server',
                onPressed: _deleting ? null : _confirmDelete,
                icon: _deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: Colors.red,
                      ),
              ),
            ],
          ),
          if (_expanded) _buildToolsSection(theme, entry, total),
        ],
      ),
    );
  }

  Widget _buildToolsSection(ThemeData theme, McpServerEntry entry, int total) {
    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'No tools discovered yet.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Text('Tools', style: theme.textTheme.labelLarge),
            const Spacer(),
            TextButton(
              onPressed: entry.enabled ? widget.onEnableAll : null,
              child: const Text('Enable all'),
            ),
            TextButton(
              onPressed: entry.enabled ? widget.onDisableAll : null,
              child: const Text('Disable all'),
            ),
          ],
        ),
        for (final tool in entry.tools)
          Opacity(
            opacity: entry.enabled ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tool.name, style: theme.textTheme.bodyMedium),
                        if ((tool.description ?? '').isNotEmpty)
                          Text(
                            tool.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  ShadSwitch(
                    value:
                        entry.enabled &&
                        !entry.disabledTools.contains(tool.name),
                    enabled: entry.enabled,
                    onChanged: (value) =>
                        widget.onToggleTool(tool.name, !value),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Changes apply when you compile.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
