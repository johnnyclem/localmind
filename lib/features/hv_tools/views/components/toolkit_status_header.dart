import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/toolkit_status.dart';

/// Header line for the tools console: when the toolkit was last compiled,
/// its stats, the embedder label, and a stale badge when [isDirty] (local
/// draft edits pending) or the server itself reports `stale:true`.
class ToolkitStatusHeader extends StatelessWidget {
  final ToolkitStatus? toolkit;
  final bool isDirty;

  const ToolkitStatusHeader({
    super.key,
    required this.toolkit,
    required this.isDirty,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = toolkit;

    if (t == null || !t.hasToolkit) {
      return ShadCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTools,
              size: 20,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No toolkit compiled yet. Add a server and tap Compile '
                'Tools to give chat access to its tools.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    final stale = isDirty || t.stale;
    final compiledLabel = t.compiledAt != null
        ? _formatDate(t.compiledAt!)
        : 'unknown time';

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Toolkit', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              if (t.embedderLabel != null)
                ShadBadge.outline(child: Text(t.embedderLabel!)),
              if (stale) ...[
                const SizedBox(width: 8),
                const ShadBadge.destructive(child: Text('Stale — recompile')),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${t.toolCount ?? '—'} tools · '
            '${t.uniqueSelectorCount ?? '—'} selectors · '
            'compiled $compiledLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
