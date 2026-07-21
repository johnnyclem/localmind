import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import 'components/claim_domain_card.dart';
import 'components/dashboard_theme_card.dart';
import 'components/domain_portfolio_grid.dart';
import 'components/plan_compare_card.dart';

/// Domains & Upgrade (mobile PRD M13): Free vs Pro compare, the vanity
/// domain portfolio picker + name/claim flow, and the owner's own dashboard
/// theme picker.
class DomainsScreen extends ConsumerWidget {
  const DomainsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilitiesAsync = ref.watch(capabilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Domains & Upgrade')),
      body: capabilitiesAsync.when(
        data: (capabilities) => RefreshIndicator(
          onRefresh: () => ref.read(capabilitiesProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              PlanCompareCard(
                maxProSubdomains: capabilities.limits.maxProSubdomains,
              ),
              const SizedBox(height: 24),
              DomainPortfolioGrid(domains: capabilities.domains),
              const SizedBox(height: 24),
              const ClaimDomainCard(),
              const SizedBox(height: 24),
              DashboardThemeCard(themes: capabilities.themes),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(context, ref, err),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    final message = err is HyperVaultApiException
        ? err.message
        : err.toString();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(capabilitiesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
