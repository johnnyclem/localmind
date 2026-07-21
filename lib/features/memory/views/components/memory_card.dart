import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/memory.dart';

/// Coarse, human-friendly relative timestamp ("just now", "5m ago", "3d
/// ago", falling back to a locale date past ~4 weeks). Mirrors
/// `lib/features/vault/views/components/artifact_card.dart`'s helper; kept
/// as a local copy rather than a cross-feature import so this feature has
/// no dependency on the sibling vault feature's file layout.
String formatMemoryRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

class MemoryCard extends StatelessWidget {
  final MemoryListItem memory;
  final VoidCallback onTap;

  const MemoryCard({super.key, required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visibleTags = memory.tags.take(6).toList();

    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    memory.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (memory.source != null && memory.source!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ShadBadge.outline(child: Text(memory.source!)),
                ],
              ],
            ),
            if (memory.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                memory.summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (visibleTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: visibleTags
                    .map(
                      (tag) => Text(
                        '#$tag',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  formatMemoryRelativeTime(memory.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (memory.score != null) ...[
                  const SizedBox(width: 12),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    memory.score!.toStringAsFixed(2),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
