/// `GET /api/claim-domain?name=&base=` response — public, rate-limited
/// 30/min/IP (mobile PRD T-M13-04). `available:false` carries a
/// human-readable [reason] ("taken", etc.); a non-2xx (rate limit/hiccup)
/// never reaches this model — callers treat that as "stay quiet" instead,
/// since the authoritative check is the claim `POST` itself.
class DomainAvailability {
  final bool available;
  final String? reason;

  const DomainAvailability({required this.available, this.reason});

  factory DomainAvailability.fromJson(Map<String, dynamic> json) =>
      DomainAvailability(
        available: json['available'] as bool? ?? false,
        reason: json['reason'] as String?,
      );
}
