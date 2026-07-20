import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_memory_recall_result.dart';

/// A recall hit: visually distinct from a plain browse card via a relevance
/// score chip and a "related" strip, so it's obvious server recall answered
/// (vs. the instant local filter).
class MemoryRecallCard extends StatelessWidget {
  final HvMemoryRecallResult result;
  final VoidCallback onTap;

  const MemoryRecallCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.04),
      border: ShadBorder.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.25),
      ),
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
                    result.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _ScoreChip(score: result.score),
              ],
            ),
            if (result.summary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                result.summary,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (result.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in result.tags.take(6))
                    ShadBadge.outline(
                      child: Text(tag, style: const TextStyle(fontSize: 10)),
                    ),
                ],
              ),
            ],
            if (result.related.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedLink01,
                    size: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Related: ${result.related.join(', ')}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final double score;

  const _ScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAiSearch02,
            size: 11,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(2),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
