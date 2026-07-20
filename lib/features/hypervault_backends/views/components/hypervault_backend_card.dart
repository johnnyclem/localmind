import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_backend.dart';

/// One connected backend row (T-M10-01): provider badge, name, default model
/// (mono), an "embeddings" badge when applicable, a truncated base URL, and
/// the key hint. Never renders the raw API key.
class HyperVaultBackendCard extends StatelessWidget {
  final HvBackend backend;
  final HvProviderSpec? spec;
  final VoidCallback onTap;

  const HyperVaultBackendCard({
    super.key,
    required this.backend,
    required this.spec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerLabel = spec?.label ?? backend.provider;
    final hasEmbeddings =
        (backend.embeddingModel?.isNotEmpty ?? false) ||
        (spec?.supportsEmbeddings ?? false);

    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      providerLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasEmbeddings) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'embeddings',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                backend.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if ((backend.defaultModel ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  backend.defaultModel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if ((backend.baseUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  backend.baseUrl!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if ((backend.keyHint ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedKey01,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      backend.keyHint!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
