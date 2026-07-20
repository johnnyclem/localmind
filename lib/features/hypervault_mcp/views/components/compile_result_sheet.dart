import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_mcp_compile_outcome.dart';

/// Compile result summary (spec T-M11-09): tools → selectors, collisions,
/// embedder, "new chats now use this toolkit", and skipped servers in a
/// warning tint.
Future<void> showCompileResultSheet(BuildContext context, HvCompileOutcome outcome) async {
  await showShadSheet(
    context: context,
    builder: (ctx) => _CompileResultSheetContent(outcome: outcome),
  );
}

class _CompileResultSheetContent extends StatelessWidget {
  final HvCompileOutcome outcome;
  const _CompileResultSheetContent({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadSheet(
      title: const Text('Toolkit compiled'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${outcome.stats.toolCount} tools → ${outcome.stats.uniqueSelectorCount} selectors',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${outcome.stats.collisionCount} collision${outcome.stats.collisionCount == 1 ? '' : 's'} · '
            '${outcome.embedderLabel}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          if (outcome.embedderDegradeReason != null) ...[
            const SizedBox(height: 6),
            Text(
              outcome.embedderDegradeReason!,
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.orange),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'New chats now use this toolkit.',
            style: theme.textTheme.bodySmall,
          ),
          if (outcome.skippedServers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedAlert02, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text('Skipped servers', style: theme.textTheme.labelMedium?.copyWith(color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final s in outcome.skippedServers)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${s.name}: ${s.error}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ShadButton(
            width: double.infinity,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
