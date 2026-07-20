/// `POST /api/claim-domain` response — the claimed realm plus the account's
/// running total against `capabilities.limits.maxProSubdomains`.
class HvDomainClaimResult {
  final String domain;
  final String url;
  final int claimed;
  final int maxSubdomains;
  final String message;

  const HvDomainClaimResult({
    required this.domain,
    required this.url,
    required this.claimed,
    required this.maxSubdomains,
    required this.message,
  });

  factory HvDomainClaimResult.fromJson(Map<String, dynamic> json) {
    return HvDomainClaimResult(
      domain: json['domain'] as String? ?? '',
      url: json['url'] as String? ?? '',
      claimed: (json['claimed'] as num?)?.toInt() ?? 0,
      maxSubdomains: (json['max_subdomains'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}

/// `PATCH /api/claim-domain` response — the restyled realm.
class HvDomainThemeResult {
  final String domain;
  final String? theme;
  final String message;

  const HvDomainThemeResult({
    required this.domain,
    this.theme,
    required this.message,
  });

  factory HvDomainThemeResult.fromJson(Map<String, dynamic> json) {
    return HvDomainThemeResult(
      domain: json['domain'] as String? ?? '',
      theme: json['theme'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}

/// A realm claimed during this session — the API has no list endpoint for a
/// user's claims (see docs/mobile/prd/13-domains-upgrade.md), so this is
/// built up locally from claim/restyle responses rather than fetched fresh.
class HvClaimedRealm {
  final String domain;
  final String url;
  final String? theme;

  const HvClaimedRealm({required this.domain, required this.url, this.theme});

  HvClaimedRealm copyWith({String? theme}) =>
      HvClaimedRealm(domain: domain, url: url, theme: theme ?? this.theme);
}
