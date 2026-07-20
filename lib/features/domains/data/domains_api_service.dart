import '../../../core/network/hypervault_client.dart';
import 'models/dashboard_theme_result.dart';
import 'models/domain_availability.dart';
import 'models/realm_restyle_result.dart';

/// Thin typed wrapper around [HyperVaultClient] for the Domains & Upgrade
/// endpoints (mobile PRD M13). Mirrors the shape of
/// `lib/features/servers/data/server_api_service.dart`.
class DomainsApiService {
  final HyperVaultClient _client;

  DomainsApiService(this._client);

  /// `GET /api/claim-domain?name=&base=` — public, rate-limited 30/min/IP.
  /// Callers should debounce (~350ms) and treat a thrown
  /// [HyperVaultApiException] as "stay quiet" rather than an error — the
  /// authoritative check is [claimDomain].
  Future<DomainAvailability> checkAvailability({
    required String name,
    required String base,
  }) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/claim-domain',
      query: {'name': name, 'base': base},
    );
    return DomainAvailability.fromJson(json);
  }

  /// `POST /api/claim-domain {desired_name, base_domain?}` ->
  /// `{domain, url, claimed, max_subdomains, message}`. Returns the raw body
  /// — the response doesn't echo `subdomain`/`base_domain` back, so the
  /// caller (which already knows [desiredName]/[baseDomain]) attaches them
  /// when building a [ClaimedDomain]. Throws [HyperVaultApiException] with
  /// `.message` verbatim on 403 (max subdomains reached) or 409 (name
  /// taken).
  Future<Map<String, dynamic>> claimDomain({
    required String desiredName,
    String? baseDomain,
  }) {
    return _client.post<Map<String, dynamic>>(
      '/api/claim-domain',
      data: {
        'desired_name': desiredName,
        if (baseDomain != null && baseDomain.isNotEmpty)
          'base_domain': baseDomain,
      },
    );
  }

  /// `PATCH /api/claim-domain {subdomain, base_domain?, theme}` — restyles a
  /// *claimed* realm's theme (what visitors see, not the owner's own
  /// dashboard).
  Future<RealmRestyleResult> restyleRealm({
    required String subdomain,
    String? baseDomain,
    required String theme,
  }) async {
    final json = await _client.patch<Map<String, dynamic>>(
      '/api/claim-domain',
      data: {
        'subdomain': subdomain,
        if (baseDomain != null && baseDomain.isNotEmpty)
          'base_domain': baseDomain,
        'theme': theme,
      },
    );
    return RealmRestyleResult.fromJson(json);
  }

  /// `PATCH /api/dashboard-theme {theme: styleId | null}` — restyles the
  /// signed-in user's own dashboard surfaces, independent of any claimed
  /// realm. Pass `null` to reset to the default theme.
  Future<DashboardThemeResult> updateDashboardTheme(String? theme) async {
    final json = await _client.patch<Map<String, dynamic>>(
      '/api/dashboard-theme',
      data: {'theme': theme},
    );
    return DashboardThemeResult.fromJson(json);
  }
}
