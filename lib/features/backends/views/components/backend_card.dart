import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/backend.dart';
import '../../utils/relative_time.dart';

class BackendCard extends StatelessWidget {
  final Backend backend;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const BackendCard({
    super.key,
    required this.backend,
    required this.onTap,
    required this.onDelete,
  });

  bool get _showsEmbeddingBadge => (backend.embeddingModel?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCloudServer,
                size: 22,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          backend.name.isNotEmpty
                              ? backend.name
                              : providerDisplayNameFor(backend.provider),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ShadBadge.secondary(
                        child: Text(providerDisplayNameFor(backend.provider)),
                      ),
                      if (_showsEmbeddingBadge)
                        ShadBadge.outline(
                          child: const Text('embeddings'),
                        ),
                    ],
                  ),
                  if (backend.defaultModel?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      backend.defaultModel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (backend.keyHint?.isNotEmpty ?? false) ...[
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedKey01,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          backend.keyHint!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (backend.lastUsedAt != null) ...[
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatRelativeTime(backend.lastUsedAt!),
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
            ShadIconButton.ghost(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Title-cases a raw provider id (e.g. `lm_studio` -> `Lm Studio`) for
/// display when we only have the id and not the full registry spec — the
/// list screen doesn't necessarily have `capabilities.providers` loaded.
String providerDisplayNameFor(String providerId) {
  if (providerId.isEmpty) return 'Unknown';
  return providerId
      .split(RegExp(r'[_-]'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
