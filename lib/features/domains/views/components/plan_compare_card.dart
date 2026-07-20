import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// T-M13-01 / T-M13-09: Free vs Pro compare card.
///
/// The Pro "Upgrade" CTA opens the external web checkout
/// (`https://hypervault.store/upgrade`) in the system browser rather than
/// any in-app purchase flow. **Flag:** payment mechanism (App Store/Play
/// IAP vs. this external web link) is an open product decision (spec
/// §13.5) — mobile deliberately does not bundle a StoreKit/Play Billing SDK
/// so this seam can later become IAP without a rewrite. Claiming a
/// subdomain itself stays fully in-app below.
class PlanCompareCard extends StatelessWidget {
  final int maxProSubdomains;

  const PlanCompareCard({super.key, required this.maxProSubdomains});

  static final Uri _upgradeUrl = Uri.parse('https://hypervault.store/upgrade');

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      title: const Text('Free vs Pro'),
      description: const Text('Compare plans before you claim a realm.'),
      footer: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ShadButton(
          width: double.infinity,
          leading: const HugeIcon(icon: HugeIcons.strokeRoundedRocket, size: 18),
          onPressed: () =>
              launchUrl(_upgradeUrl, mode: LaunchMode.externalApplication),
          child: const Text('Upgrade to Pro'),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PlanColumn(
                  title: 'Free',
                  price: '\$0 / forever',
                  bullets: const [
                    'Personal vault & sign-in dashboard',
                    '0 claimed vanity subdomains',
                  ],
                  highlighted: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PlanColumn(
                  title: 'Pro',
                  price: '\$8 / mo',
                  bullets: [
                    'Permanent vault',
                    'Up to $maxProSubdomains legendary addresses',
                    'Vault on every subdomain',
                    'Custom landing + priority rendering',
                  ],
                  highlighted: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanColumn extends StatelessWidget {
  final String title;
  final String price;
  final List<String> bullets;
  final bool highlighted;

  const _PlanColumn({
    required this.title,
    required this.price,
    required this.bullets,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: highlighted ? 1.5 : 1,
        ),
        color: highlighted ? colorScheme.primary.withAlpha(15) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (highlighted) ...[
                const SizedBox(width: 6),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCrown,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
          Text(
            price,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTick02,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(b, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
