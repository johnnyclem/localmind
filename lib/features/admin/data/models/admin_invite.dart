/// A row from the `invite_codes` table (mobile PRD M15).
///
/// Read directly from Supabase (there is no `GET /api/admin/invites` list
/// route — see `admin_providers.dart`); created/enabled/disabled/destroyed
/// via the real `/api/admin/invites*` REST routes.
class AdminInvite {
  final String id;
  final String code;
  final String? note;
  final int maxUses;
  final int useCount;
  final bool disabled;
  final DateTime? createdAt;

  const AdminInvite({
    required this.id,
    required this.code,
    required this.maxUses,
    required this.useCount,
    required this.disabled,
    this.note,
    this.createdAt,
  });

  bool get isExhausted => useCount >= maxUses;

  factory AdminInvite.fromJson(Map<String, dynamic> json) {
    return AdminInvite(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      note: json['note'] as String?,
      maxUses: (json['max_uses'] as num?)?.toInt() ?? 1,
      useCount: (json['use_count'] as num?)?.toInt() ?? 0,
      disabled: json['disabled'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  AdminInvite copyWith({bool? disabled, int? useCount}) {
    return AdminInvite(
      id: id,
      code: code,
      note: note,
      maxUses: maxUses,
      useCount: useCount ?? this.useCount,
      disabled: disabled ?? this.disabled,
      createdAt: createdAt,
    );
  }
}
