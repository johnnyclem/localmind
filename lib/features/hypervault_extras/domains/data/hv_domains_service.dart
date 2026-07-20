import '../../../hypervault/data/hypervault_api_client.dart';
import 'models/hv_domain_availability.dart';
import 'models/hv_domain_claim.dart';

/// Typed wrapper over `GET/POST/PATCH /api/claim-domain` (spec
/// docs/mobile/prd/13-domains-upgrade.md). `GET` is public, but this still
/// routes through [HyperVaultApiClient] for base-URL consistency with the
/// rest of the app.
class HvDomainsService {
  final HyperVaultApiClient _client;

  const HvDomainsService(this._client);

  Future<HvDomainAvailability> checkAvailability({
    required String name,
    required String base,
  }) async {
    final json = await _client.get(
      '/api/claim-domain',
      query: {'name': name, 'base': base},
    );
    return HvDomainAvailability.fromJson(json);
  }

  Future<HvDomainClaimResult> claim({
    required String desiredName,
    String? baseDomain,
  }) async {
    final json = await _client.post(
      '/api/claim-domain',
      body: {
        'desired_name': desiredName,
        if (baseDomain != null && baseDomain.isNotEmpty)
          'base_domain': baseDomain,
      },
    );
    return HvDomainClaimResult.fromJson(json);
  }

  Future<HvDomainThemeResult> restyle({
    required String subdomain,
    String? baseDomain,
    required String? theme,
  }) async {
    final json = await _client.patch(
      '/api/claim-domain',
      body: {
        'subdomain': subdomain,
        if (baseDomain != null && baseDomain.isNotEmpty)
          'base_domain': baseDomain,
        'theme': theme,
      },
    );
    return HvDomainThemeResult.fromJson(json);
  }
}
