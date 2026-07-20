import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../../hypervault/providers/hypervault_providers.dart';
import '../data/hv_domains_service.dart';
import '../data/models/hv_domain_claim.dart';

final hvDomainsServiceProvider = Provider<HvDomainsService>((ref) {
  return HvDomainsService(ref.read(hyperVaultApiClientProvider));
});

enum HvAvailabilityStatus { idle, checking, available, unavailable }

class HvAvailabilityState {
  final HvAvailabilityStatus status;
  final String? reason;

  const HvAvailabilityState({
    this.status = HvAvailabilityStatus.idle,
    this.reason,
  });
}

/// Debounced (350ms) live availability check (spec T-M13-04). A non-OK
/// response (rate limit/hiccup) stays quiet — it never blocks claiming,
/// which validates server-side regardless.
final hvDomainAvailabilityProvider =
    NotifierProvider<HvDomainAvailabilityNotifier, HvAvailabilityState>(
      HvDomainAvailabilityNotifier.new,
    );

class HvDomainAvailabilityNotifier extends Notifier<HvAvailabilityState> {
  Timer? _debounce;

  @override
  HvAvailabilityState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const HvAvailabilityState();
  }

  void reset() {
    _debounce?.cancel();
    state = const HvAvailabilityState();
  }

  void check(String name, String base) {
    _debounce?.cancel();
    if (name.trim().isEmpty) {
      state = const HvAvailabilityState();
      return;
    }
    state = const HvAvailabilityState(status: HvAvailabilityStatus.checking);
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _run(name, base),
    );
  }

  Future<void> _run(String name, String base) async {
    try {
      final result = await ref
          .read(hvDomainsServiceProvider)
          .checkAvailability(name: name, base: base);
      state = HvAvailabilityState(
        status: result.available
            ? HvAvailabilityStatus.available
            : HvAvailabilityStatus.unavailable,
        reason: result.reason,
      );
    } catch (_) {
      // Quiet failure per spec — claim() is still the authoritative check.
      state = const HvAvailabilityState();
    }
  }
}

/// Realms claimed/restyled during this session. There's no
/// `GET`-list-your-claims endpoint in the API contract, so this is built up
/// locally from claim/restyle responses rather than fetched fresh — flagged
/// in integrationNotes.
final hvClaimedRealmsProvider =
    NotifierProvider<HvClaimedRealmsNotifier, List<HvClaimedRealm>>(
      HvClaimedRealmsNotifier.new,
    );

class HvClaimedRealmsNotifier extends Notifier<List<HvClaimedRealm>> {
  @override
  List<HvClaimedRealm> build() => const [];

  void upsert(HvClaimedRealm realm) {
    final without = state.where((r) => r.domain != realm.domain).toList();
    state = [...without, realm];
  }

  void setTheme(String domain, String? theme) {
    state = [
      for (final r in state)
        if (r.domain == domain) r.copyWith(theme: theme) else r,
    ];
  }
}

class HvDomainsScreenState {
  final bool claiming;
  final String? claimError;
  final HvDomainClaimResult? lastClaim;

  const HvDomainsScreenState({
    this.claiming = false,
    this.claimError,
    this.lastClaim,
  });
}

/// Drives the claim action; kept separate from [hvDomainAvailabilityProvider]
/// so a claim in flight doesn't fight the debounced availability checker.
final hvDomainsScreenProvider =
    NotifierProvider<HvDomainsScreenNotifier, HvDomainsScreenState>(
      HvDomainsScreenNotifier.new,
    );

class HvDomainsScreenNotifier extends Notifier<HvDomainsScreenState> {
  @override
  HvDomainsScreenState build() => const HvDomainsScreenState();

  Future<HvDomainClaimResult?> claim({
    required String desiredName,
    required String baseDomain,
  }) async {
    state = const HvDomainsScreenState(claiming: true);
    try {
      final result = await ref
          .read(hvDomainsServiceProvider)
          .claim(desiredName: desiredName, baseDomain: baseDomain);
      ref
          .read(hvClaimedRealmsProvider.notifier)
          .upsert(HvClaimedRealm(domain: result.domain, url: result.url));
      state = HvDomainsScreenState(lastClaim: result);
      return result;
    } on HvApiError catch (e) {
      state = HvDomainsScreenState(claimError: e.error);
      return null;
    }
  }

  void clear() => state = const HvDomainsScreenState();
}
