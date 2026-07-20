/// `GET /api/claim-domain?name=&base=` response.
class HvDomainAvailability {
  final bool available;
  final String? reason;

  const HvDomainAvailability({required this.available, this.reason});

  factory HvDomainAvailability.fromJson(Map<String, dynamic> json) {
    return HvDomainAvailability(
      available: json['available'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }
}
