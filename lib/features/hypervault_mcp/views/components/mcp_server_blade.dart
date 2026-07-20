import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_mcp_server.dart';

/// Expandable server blade: master enable switch, tool-count badge, key icon
/// when `hasAuth`, and (expanded) a per-tool switch list with enable-all /
/// disable-all shortcuts. Every toggle here mutates the draft only — the
/// "changes apply when you compile" hint makes that explicit (spec T-M11-03).
class McpServerBlade extends StatefulWidget {
  final HvMcpServer persisted;
  final HvMcpServer draft;
  final bool refreshing;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<String> onToggleTool;
  final ValueChanged<bool> onSetAllTools;
  final VoidCallback onRefresh;
  final VoidCallback onRename;
  final VoidCallback onEditHeaders;
  final VoidCallback onDelete;

  const McpServerBlade({
    super.key,
    required this.persisted,
    required this.draft,
    required this.refreshing,
    required this.onToggleEnabled,
    required this.onToggleTool,
    required this.onSetAllTools,
    required this.onRefresh,
    required this.onRename,
    required this.onEditHeaders,
    required this.onDelete,
  });

  @override
  State<McpServerBlade> createState() => _McpServerBladeState();
}

class _McpServerBladeState extends State<McpServerBlade> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = widget.draft;
    final totalTools = draft.toolsCache.length;
    final enabledTools = draft.enabledToolCount;
    final dirty =
        widget.persisted.enabled != draft.enabled ||
        widget.persisted.disabledTools.toSet().difference(draft.disabledTools.toSet()).isNotEmpty ||
        draft.disabledTools.toSet().difference(widget.persisted.disabledTools.toSet()).isNotEmpty;

    return ShadCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: totalTools == 0
                ? null
                : () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                                draft.name,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            if (draft.hasAuth) ...[
                              const SizedBox(width: 6),
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedKey02,
                                size: 14,
                                color: theme.colorScheme.outline,
                              ),
                            ],
                            if (dirty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'pending',
                                  style: TextStyle(fontSize: 10, color: Colors.orange),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          draft.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalTools == 0
                              ? 'off'
                              : '$enabledTools/$totalTools tools enabled',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: '${draft.name} enabled',
                    toggled: draft.enabled,
                    child: ShadSwitch(
                      value: draft.enabled,
                      onChanged: widget.onToggleEnabled,
                    ),
                  ),
                  _BladeMenu(
                    refreshing: widget.refreshing,
                    onRefresh: widget.onRefresh,
                    onRename: widget.onRename,
                    onEditHeaders: widget.onEditHeaders,
                    onDelete: widget.onDelete,
                  ),
                  if (totalTools > 0)
                    HugeIcon(
                      icon: _expanded
                          ? HugeIcons.strokeRoundedToggleOn
                          : HugeIcons.strokeRoundedToggleOff,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                ],
              ),
            ),
          ),
          if (_expanded && totalTools > 0)
            _ToolList(
              draft: draft,
              onToggleTool: widget.onToggleTool,
              onSetAllTools: widget.onSetAllTools,
            ),
        ],
      ),
    );
  }
}

class _BladeMenu extends StatelessWidget {
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onRename;
  final VoidCallback onEditHeaders;
  final VoidCallback onDelete;

  const _BladeMenu({
    required this.refreshing,
    required this.onRefresh,
    required this.onRename,
    required this.onEditHeaders,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (refreshing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return PopupMenuButton<String>(
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 18),
      onSelected: (value) {
        switch (value) {
          case 'refresh':
            onRefresh();
          case 'rename':
            onRename();
          case 'headers':
            onEditHeaders();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'refresh', child: Text('Refresh tools')),
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'headers', child: Text('Edit auth headers')),
        PopupMenuItem(value: 'delete', child: Text('Remove')),
      ],
    );
  }
}

class _ToolList extends StatelessWidget {
  final HvMcpServer draft;
  final ValueChanged<String> onToggleTool;
  final ValueChanged<bool> onSetAllTools;

  const _ToolList({
    required this.draft,
    required this.onToggleTool,
    required this.onSetAllTools,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = draft.disabledTools.toSet();
    final serverOff = !draft.enabled;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Opacity(
            opacity: serverOff ? 0.4 : 1,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    draft.introspectedAt != null
                        ? 'Last refreshed ${DateFormat.yMMMd().add_jm().format(draft.introspectedAt!.toLocal())}'
                        : 'Not yet introspected',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: serverOff ? null : () => onSetAllTools(true),
                  child: const Text('Enable all', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: serverOff ? null : () => onSetAllTools(false),
                  child: const Text('Disable all', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          for (final tool in draft.toolsCache)
            Opacity(
              opacity: serverOff ? 0.4 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tool.name, style: theme.textTheme.bodySmall),
                          if (tool.description.isNotEmpty)
                            Text(
                              tool.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: '${tool.name} enabled',
                      toggled: !disabled.contains(tool.name),
                      child: ShadSwitch(
                        value: !disabled.contains(tool.name),
                        enabled: !serverOff,
                        onChanged: serverOff ? null : (_) => onToggleTool(tool.name),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Changes apply when you compile.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
