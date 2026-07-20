import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_memory_summary.dart';

/// A wiki index entry: title, date, summary, source badge, up to 6 tags.
/// Used for browse mode and the instant local-filter pass over it.
class MemoryBrowseCard extends StatelessWidget {
  final HvMemorySummary memory;
  final VoidCallback onTap;

  const MemoryBrowseCard({
    super.key,
    required this.memory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    memory.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (memory.createdAt != null)
                  Text(
                    DateFormat.yMMMd().format(memory.createdAt!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            if (memory.summary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                memory.summary,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ShadBadge.secondary(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedFolderLibrary,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(memory.source, style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                for (final tag in memory.tags.take(6))
                  ShadBadge.outline(
                    child: Text(tag, style: const TextStyle(fontSize: 10)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
