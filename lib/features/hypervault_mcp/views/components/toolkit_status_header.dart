import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_mcp_toolkit_status.dart';

/// Toolkit status header (spec T-M11-08): compiled-at, tool/selector counts,
/// embedder label, and a stale badge nudging a recompile.
class ToolkitStatusHeader extends StatelessWidget {
  final HvToolkitStatus status;

  const ToolkitStatusHeader({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolkit = status.toolkit;

    if (toolkit == null) {
      return ShadCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedCpu, color: theme.colorScheme.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No toolkit compiled yet — enable a server\'s tools and compile '
                'to use them in chat.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return ShadCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedCpu, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${toolkit.stats.toolCount} tools → ${toolkit.stats.uniqueSelectorCount} selectors',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (status.stale) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'stale — recompile',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (toolkit.compiledAt != null)
                      'Compiled ${DateFormat.yMMMd().add_jm().format(toolkit.compiledAt!.toLocal())}',
                    toolkit.embedderLabel,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
