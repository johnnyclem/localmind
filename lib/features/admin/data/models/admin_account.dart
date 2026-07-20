/// A merged view of a `profiles` row and its matching `account_access` row
/// (mobile PRD M15). There is no FK between the two tables (both reference
/// `auth.users(id)` independently), so — mirroring the web admin page — the
/// two tables are queried separately and joined client-side by id rather
/// than via a Postgrest embed.
class AdminAccount {
  final String id;
  final String? email;
  final String? displayName;
  final String plan;
  final String? vanitySubdomain;
  final DateTime? createdAt;

  /// Null when the profile has no matching `account_access` row (i.e. still
  /// waitlisted); otherwise the `source` column ('invite' | 'admin' |
  /// 'legacy').
  final String? accessSource;

  const AdminAccount({
    required this.id,
    required this.plan,
    this.email,
    this.displayName,
    this.vanitySubdomain,
    this.createdAt,
    this.accessSource,
  });

  bool get hasAccess => accessSource != null;

  factory AdminAccount.fromJson(
    Map<String, dynamic> json, {
    String? accessSource,
  }) {
    return AdminAccount(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      plan: json['plan'] as String? ?? 'free',
      vanitySubdomain: json['vanity_subdomain'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      accessSource: accessSource,
    );
  }

  AdminAccount copyWith({String? plan, Object? accessSource = _unset}) {
    return AdminAccount(
      id: id,
      email: email,
      displayName: displayName,
      plan: plan ?? this.plan,
      vanitySubdomain: vanitySubdomain,
      createdAt: createdAt,
      accessSource: identical(accessSource, _unset)
          ? this.accessSource
          : accessSource as String?,
    );
  }
}

const _unset = Object();
