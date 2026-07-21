/// A realm claimed via `POST /api/claim-domain` this session.
///
/// There is no "list my claimed domains" GET endpoint in the API contract
/// (mobile PRD M13) — the claim response is the only record the app has, so
/// this is kept in local Riverpod state ([claimedDomainsProvider]) rather
/// than fetched. [subdomain]/[baseDomain] are captured client-side from the
/// original claim request (the response only echoes back the combined
/// [domain]) so a later restyle `PATCH` knows what to target.
class ClaimedDomain {
  final String domain;
  final String url;
  final bool claimed;
  final int? maxSubdomains;
  final String? message;
  final String subdomain;
  final String baseDomain;
  final String? theme;

  const ClaimedDomain({
    required this.domain,
    required this.url,
    required this.claimed,
    required this.subdomain,
    required this.baseDomain,
    this.maxSubdomains,
    this.message,
    this.theme,
  });

  factory ClaimedDomain.fromResponse(
    Map<String, dynamic> json, {
    required String subdomain,
    required String baseDomain,
  }) {
    return ClaimedDomain(
      domain: json['domain'] as String? ?? '$subdomain.$baseDomain',
      url: json['url'] as String? ?? '',
      claimed: json['claimed'] as bool? ?? true,
      maxSubdomains: json['max_subdomains'] as int?,
      message: json['message'] as String?,
      subdomain: subdomain,
      baseDomain: baseDomain,
    );
  }

  ClaimedDomain copyWith({String? theme}) => ClaimedDomain(
    domain: domain,
    url: url,
    claimed: claimed,
    maxSubdomains: maxSubdomains,
    message: message,
    subdomain: subdomain,
    baseDomain: baseDomain,
    theme: theme ?? this.theme,
  );
}
