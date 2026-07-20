import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/artifact.dart';

/// Renders a coarse, human-friendly relative timestamp ("just now", "5m
/// ago", "3d ago", falling back to a locale date past ~4 weeks). No
/// dependency is added for this — it is intentionally simple.
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

class ArtifactCard extends StatelessWidget {
  final Artifact artifact;
  final VoidCallback onTap;

  const ArtifactCard({super.key, required this.artifact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    artifact.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ShadBadge.outline(
                  child: Text(artifact.visibility == 'public' ? 'Public' : 'Private'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ShadBadge.secondary(child: Text(artifact.type)),
                if (artifact.isJsx)
                  const ShadBadge(child: Text('React · auto-wrapped')),
                if (artifact.isPwa)
                  ShadBadge.outline(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedRocket01,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text('Installable'),
                      ],
                    ),
                  ),
              ],
            ),
            if (artifact.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: artifact.tags
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
                  formatRelativeTime(artifact.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
