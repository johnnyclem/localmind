import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../../hypervault/data/models/hv_capabilities.dart';
import '../../../hypervault/providers/hypervault_providers.dart';
import '../data/models/hv_domain_claim.dart';
import '../data/subdomain_validator.dart';
import '../providers/hv_domains_providers.dart';
import 'components/domain_portfolio_grid.dart';
import 'components/restyle_realm_sheet.dart';

/// Domains & Upgrade (spec docs/mobile/prd/13-domains-upgrade.md): Free-vs-Pro
/// compare, the vanity portfolio picker, live availability, one-tap claim,
/// and per-realm restyle. Payment stays out-of-app (T-M13-09) — the Pro CTA
/// deep-links to `capabilities.appUrl + "/upgrade"` in the system browser;
/// no IAP SDK is bundled.
class HvDomainsScreen extends ConsumerStatefulWidget {
  const HvDomainsScreen({super.key});

  @override
  ConsumerState<HvDomainsScreen> createState() => _HvDomainsScreenState();
}

class _HvDomainsScreenState extends ConsumerState<HvDomainsScreen> {
  final _nameController = TextEditingController();
  String? _selectedBase;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value, String base) {
    setState(() {});
    final validation = validateSubdomain(value);
    if (validation.ok) {
      ref
          .read(hvDomainAvailabilityProvider.notifier)
          .check(validation.name!, base);
    } else {
      ref.read(hvDomainAvailabilityProvider.notifier).reset();
    }
  }

  Future<void> _openUpgrade(String appUrl) async {
    final uri = Uri.tryParse('$appUrl/upgrade');
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _claim(String base, String name) async {
    final validation = validateSubdomain(name);
    if (!validation.ok) return;
    final result = await ref
        .read(hvDomainsScreenProvider.notifier)
        .claim(desiredName: validation.name!, baseDomain: base);
    if (result != null) {
      _nameController.clear();
      ref.read(hvDomainAvailabilityProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capabilities = ref.watch(hyperVaultCapabilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Domains & Upgrade')),
      body: SafeArea(
        child: capabilities.when(
          data: (caps) => _Body(
            caps: caps,
            nameController: _nameController,
            selectedBase: _selectedBase ?? _defaultBase(caps.domains),
            onSelectBase: (base) {
              setState(() => _selectedBase = base);
              _onNameChanged(_nameController.text, base);
            },
            onNameChanged: (value) => _onNameChanged(
              value,
              _selectedBase ?? _defaultBase(caps.domains),
            ),
            onOpenUpgrade: () => _openUpgrade(caps.appUrl),
            onOpenUrl: _openUrl,
            onClaim: () => _claim(
              _selectedBase ?? _defaultBase(caps.domains),
              _nameController.text,
            ),
            onRestyle: (realm) => showRestyleRealmSheet(
              context,
              realm: realm,
              themes: caps.themes,
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                err is HvApiError ? err.error : 'Could not load capabilities.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _defaultBase(List<HvDomain> domains) {
  if (domains.isEmpty) return 'vault.cool';
  final featured = domains.where((d) => d.featured && d.available);
  if (featured.isNotEmpty) return featured.first.domain;
  final available = domains.where((d) => d.available);
  if (available.isNotEmpty) return available.first.domain;
  return domains.first.domain;
}

class _Body extends ConsumerWidget {
  final HvCapabilities caps;
  final TextEditingController nameController;
  final String selectedBase;
  final ValueChanged<String> onSelectBase;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onOpenUpgrade;
  final ValueChanged<String> onOpenUrl;
  final VoidCallback onClaim;
  final ValueChanged<HvClaimedRealm> onRestyle;

  const _Body({
    required this.caps,
    required this.nameController,
    required this.selectedBase,
    required this.onSelectBase,
    required this.onNameChanged,
    required this.onOpenUpgrade,
    required this.onOpenUrl,
    required this.onClaim,
    required this.onRestyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final validation = validateSubdomain(nameController.text);
    final availability = ref.watch(hvDomainAvailabilityProvider);
    final screenState = ref.watch(hvDomainsScreenProvider);
    final claimedRealms = ref.watch(hvClaimedRealmsProvider);

    final nameEmpty = nameController.text.trim().isEmpty;
    final canClaim =
        !nameEmpty &&
        validation.ok &&
        availability.status != HvAvailabilityStatus.unavailable &&
        !screenState.claiming;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _PricingCompare(
          maxSubdomains: caps.limits.maxProSubdomains,
          onUpgrade: onOpenUpgrade,
        ),
        const SizedBox(height: 24),
        Text('Pick your address', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        DomainPortfolioGrid(
          domains: caps.domains,
          selectedBase: selectedBase,
          name: nameController.text,
          onSelect: onSelectBase,
        ),
        const SizedBox(height: 16),
        ShadInputFormField(
          controller: nameController,
          label: const Text('Name'),
          placeholder: const Text('yourname'),
          autocorrect: false,
          onChanged: onNameChanged,
        ),
        const SizedBox(height: 8),
        if (!nameEmpty)
          _AvailabilityIndicator(
            validation: validation,
            availability: availability,
          ),
        const SizedBox(height: 16),
        if (screenState.claimError != null) ...[
          Text(
            screenState.claimError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 10),
        ],
        ShadButton(
          width: double.infinity,
          enabled: canClaim,
          leading: screenState.claiming
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onPressed: onClaim,
          child: Text(screenState.claiming ? 'Claiming…' : 'Claim subdomain'),
        ),
        if (screenState.lastClaim != null) ...[
          const SizedBox(height: 12),
          _ClaimSuccessCard(result: screenState.lastClaim!, onVisit: onOpenUrl),
        ],
        if (claimedRealms.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Your realms', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final realm in claimedRealms)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RealmRow(
                realm: realm,
                onVisit: onOpenUrl,
                onRestyle: () => onRestyle(realm),
              ),
            ),
        ],
      ],
    );
  }
}

class _PricingCompare extends StatelessWidget {
  final int maxSubdomains;
  final VoidCallback onUpgrade;

  const _PricingCompare({required this.maxSubdomains, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ShadCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Free', style: theme.textTheme.titleSmall),
                Text('\$0 / forever', style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                const _Feature('Permanent vault'),
                const _Feature('Chat, memory, git-mind'),
                const _Feature('MCP tools'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ShadCard(
            padding: const EdgeInsets.all(14),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            border: ShadBorder.fromBorderSide(
              ShadBorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCrown,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text('Pro', style: theme.textTheme.titleSmall),
                  ],
                ),
                Text('\$8 / mo', style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                Text(
                  'Everything in Free, plus:',
                  style: theme.textTheme.bodySmall,
                ),
                _Feature('Up to $maxSubdomains legendary addresses'),
                const _Feature('Vault on every subdomain'),
                const _Feature('Custom landing + restyle'),
                const _Feature('Priority rendering'),
                const SizedBox(height: 10),
                ShadButton(
                  width: double.infinity,
                  size: ShadButtonSize.sm,
                  onPressed: onUpgrade,
                  child: const Text('Upgrade to Pro'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final String label;

  const _Feature(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedTick01, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityIndicator extends StatelessWidget {
  final SubdomainValidation validation;
  final HvAvailabilityState availability;

  const _AvailabilityIndicator({
    required this.validation,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!validation.ok) {
      return Text(
        validation.error ?? 'Invalid name.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    return Semantics(
      liveRegion: true,
      child: switch (availability.status) {
        HvAvailabilityStatus.idle => const SizedBox.shrink(),
        HvAvailabilityStatus.checking => Text(
          'Checking…',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        HvAvailabilityStatus.available => Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 6),
            Text(
              'Available',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
            ),
          ],
        ),
        HvAvailabilityStatus.unavailable => Text(
          availability.reason ?? 'Not available.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      },
    );
  }
}

class _ClaimSuccessCard extends StatelessWidget {
  final HvDomainClaimResult result;
  final ValueChanged<String> onVisit;

  const _ClaimSuccessCard({required this.result, required this.onVisit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.domain,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Text(result.message, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            leading: const HugeIcon(
              icon: HugeIcons.strokeRoundedLink01,
              size: 14,
            ),
            onPressed: () => onVisit(result.url),
            child: const Text('Visit it'),
          ),
        ],
      ),
    );
  }
}

class _RealmRow extends StatelessWidget {
  final HvClaimedRealm realm;
  final ValueChanged<String> onVisit;
  final VoidCallback onRestyle;

  const _RealmRow({
    required this.realm,
    required this.onVisit,
    required this.onRestyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        realm.domain,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShadBadge.secondary(
                      child: Text(
                        realm.theme ?? 'default',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Restyle',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedPaintBucket,
              size: 18,
            ),
            onPressed: onRestyle,
          ),
          IconButton(
            tooltip: 'Visit',
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedLink01, size: 18),
            onPressed: () => onVisit(realm.url),
          ),
        ],
      ),
    );
  }
}
