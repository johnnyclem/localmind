import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/toolkit_status.dart';

/// Small result summary shown after a successful `POST
/// /api/toolkits/compile` — every field is read defensively since the exact
/// success shape isn't guaranteed.
class CompileResultCard extends StatelessWidget {
  final CompileResult result;

  const CompileResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final collisions = result.collisionCount;

    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${result.toolCount ?? '—'} tools → '
                  '${result.uniqueSelectorCount ?? '—'} selectors'
                  '${collisions != null ? ' · $collisions collisions' : ''}. '
                  'New chats now use this toolkit.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (result.skippedServers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedAlert01,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Skipped: ${result.skippedServers.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
