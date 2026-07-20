/// A grantee row from `GET /api/shares?artifact={id|slug}`.
class HvShare {
  final String id;
  final String email;
  final String? displayName;
  final DateTime? createdAt;

  const HvShare({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
  });

  factory HvShare.fromJson(Map<String, dynamic> json) {
    return HvShare(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
