import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/models/hypervault_capabilities.dart';
import '../../providers/domains_providers.dart';

/// T-M13-02: grid of `capabilities.domains`. Selecting an available domain
/// sets it as the `base_domain` for the claim flow below; the featured (or
/// else first available) domain is pre-selected. `available:false` entries
/// render as "Coming soon" and are not selectable.
class DomainPortfolioGrid extends ConsumerStatefulWidget {
  final List<HyperVaultDomain> domains;

  const DomainPortfolioGrid({super.key, required this.domains});

  @override
  ConsumerState<DomainPortfolioGrid> createState() =>
      _DomainPortfolioGridState();
}

class _DomainPortfolioGridState extends ConsumerState<DomainPortfolioGrid> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSelect());
  }

  void _autoSelect() {
    if (!mounted) return;
    if (ref.read(selectedBaseDomainProvider) != null) return;
    if (widget.domains.isEmpty) return;
    final available = widget.domains.where((d) => d.available).toList();
    if (available.isEmpty) return;
    final featured = available.where((d) => d.featured).toList();
    final pick = featured.isNotEmpty ? featured.first : available.first;
    ref.read(selectedBaseDomainProvider.notifier).select(pick.domain);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedBaseDomainProvider);

    if (widget.domains.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Domain portfolio',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: widget.domains.length,
          itemBuilder: (context, index) {
            final domain = widget.domains[index];
            return _DomainCard(
              domain: domain,
              isSelected: domain.domain == selected,
              onTap: domain.available
                  ? () => ref
                        .read(selectedBaseDomainProvider.notifier)
                        .select(domain.domain)
                  : null,
            );
          },
        ),
      ],
    );
  }
}

class _DomainCard extends StatelessWidget {
  final HyperVaultDomain domain;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DomainCard({
    required this.domain,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disabled = !domain.available;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
            color: isSelected ? colorScheme.primary.withAlpha(15) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      domain.domain,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (domain.featured)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedStar,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                ],
              ),
              if (domain.tagline.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  domain.tagline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (disabled) ...[
                const SizedBox(height: 4),
                Text(
                  'Coming soon',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
