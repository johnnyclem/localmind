import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../hypervault/data/models/hv_capabilities.dart';

/// Base-domain portfolio picker (spec T-M13-02): `capabilities.domains`
/// entries, featured/coming-soon badged, coming-soon disabled. [name] feeds
/// the live `name.base` preview on each card.
class DomainPortfolioGrid extends StatelessWidget {
  final List<HvDomain> domains;
  final String selectedBase;
  final String name;
  final ValueChanged<String> onSelect;

  const DomainPortfolioGrid({
    super.key,
    required this.domains,
    required this.selectedBase,
    required this.name,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final domain in domains)
          _DomainCard(
            domain: domain,
            selected: domain.domain == selectedBase,
            preview: name.trim().isEmpty
                ? null
                : '${name.trim()}.${domain.domain}',
            onTap: domain.available ? () => onSelect(domain.domain) : null,
            theme: theme,
          ),
      ],
    );
  }
}

class _DomainCard extends StatelessWidget {
  final HvDomain domain;
  final bool selected;
  final String? preview;
  final VoidCallback? onTap;
  final ThemeData theme;

  const _DomainCard({
    required this.domain,
    required this.selected,
    required this.preview,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
          color: disabled
              ? theme.colorScheme.surface.withValues(alpha: 0.5)
              : theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    domain.domain,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontFamily: 'monospace',
                      color: disabled ? theme.colorScheme.outline : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected)
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (domain.featured)
              ShadBadge(
                child: const Text('Featured', style: TextStyle(fontSize: 10)),
              )
            else if (!domain.available)
              ShadBadge.secondary(
                child: const Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            if (domain.tagline != null) ...[
              const SizedBox(height: 6),
              Text(
                domain.tagline!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (preview != null && !disabled) ...[
              const SizedBox(height: 8),
              Text(
                preview!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
