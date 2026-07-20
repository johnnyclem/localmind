/// `PATCH /api/claim-domain {subdomain, base_domain?, theme}` response —
/// restyles a *claimed* realm's theme (what visitors see), not the owner's
/// own dashboard (mobile PRD T-M13-07).
class RealmRestyleResult {
  final String domain;
  final String theme;
  final String? message;

  const RealmRestyleResult({
    required this.domain,
    required this.theme,
    this.message,
  });

  factory RealmRestyleResult.fromJson(Map<String, dynamic> json) =>
      RealmRestyleResult(
        domain: json['domain'] as String? ?? '',
        theme: json['theme'] as String? ?? '',
        message: json['message'] as String?,
      );
}
