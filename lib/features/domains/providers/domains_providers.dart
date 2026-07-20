import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/hypervault_providers.dart';
import '../data/domains_api_service.dart';
import '../data/models/claimed_domain.dart';

final domainsApiServiceProvider = Provider<DomainsApiService>((ref) {
  return DomainsApiService(ref.watch(hypervaultClientProvider));
});

/// The base domain currently selected in the portfolio grid, used as
/// `base_domain` for the availability check and claim flow (mobile PRD
/// T-M13-02). `null` until the screen auto-selects the featured/first
/// available domain or the user taps one.
class SelectedBaseDomainNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String domain) => state = domain;
}

final selectedBaseDomainProvider =
    NotifierProvider<SelectedBaseDomainNotifier, String?>(
      SelectedBaseDomainNotifier.new,
    );

/// Realms claimed *this session*.
///
/// There is no "list my claimed domains" GET endpoint in the API contract
/// (mobile PRD M13) — this is local-only state seeded from each successful
/// `POST /api/claim-domain` response so the user can see and open what they
/// just claimed. It does not survive an app restart and does not reflect
/// realms claimed in a previous session or on another device; a persistent
/// "my realms" list is a backend gap, not something solvable client-side.
class ClaimedDomainsNotifier extends Notifier<List<ClaimedDomain>> {
  @override
  List<ClaimedDomain> build() => const [];

  /// `POST /api/claim-domain`. Throws [HyperVaultApiException] (403 max
  /// subdomains reached, 409 name taken) — callers show `.message` verbatim.
  Future<ClaimedDomain> claim({
    required String desiredName,
    required String baseDomain,
  }) async {
    final api = ref.read(domainsApiServiceProvider);
    final json = await api.claimDomain(
      desiredName: desiredName,
      baseDomain: baseDomain,
    );
    final result = ClaimedDomain.fromResponse(
      json,
      subdomain: desiredName,
      baseDomain: baseDomain,
    );
    state = [...state, result];
    return result;
  }

  /// Optimistically applies [themeId] to the realm identified by [domain],
  /// persists via `PATCH /api/claim-domain`, and rolls back on failure.
  Future<void> restyle({required String domain, required String themeId}) async {
    final previous = state;
    final idx = previous.indexWhere((d) => d.domain == domain);
    if (idx == -1) return;
    final target = previous[idx];

    final optimistic = [...previous];
    optimistic[idx] = target.copyWith(theme: themeId);
    state = optimistic;

    try {
      final api = ref.read(domainsApiServiceProvider);
      final result = await api.restyleRealm(
        subdomain: target.subdomain,
        baseDomain: target.baseDomain,
        theme: themeId,
      );
      final updated = [...state];
      final updatedIdx = updated.indexWhere((d) => d.domain == domain);
      if (updatedIdx != -1) {
        updated[updatedIdx] = updated[updatedIdx].copyWith(
          theme: result.theme.isNotEmpty ? result.theme : themeId,
        );
        state = updated;
      }
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}

final claimedDomainsProvider =
    NotifierProvider<ClaimedDomainsNotifier, List<ClaimedDomain>>(
      ClaimedDomainsNotifier.new,
    );

/// The signed-in user's own dashboard theme (`profiles.theme`), independent
/// of any claimed realm (mobile PRD T-M13-08). Optimistic with rollback on
/// failure.
class DashboardThemeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// `PATCH /api/dashboard-theme`. Pass `null` to reset to default.
  Future<void> setTheme(String? themeId) async {
    final previous = state;
    state = themeId;
    try {
      final api = ref.read(domainsApiServiceProvider);
      await api.updateDashboardTheme(themeId);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}

final dashboardThemeProvider =
    NotifierProvider<DashboardThemeNotifier, String?>(
      DashboardThemeNotifier.new,
    );
