/// One row from `invite_codes` — returned by `POST /api/admin/invites` and
/// echoed back by `PATCH /api/admin/invites/[id]`. There's no list endpoint
/// (spec docs/mobile/prd/15-admin.md), so the app only ever sees invites it
/// created or edited this session.
class HvInvite {
  final String id;
  final String code;
  final String? note;
  final int maxUses;
  final int useCount;
  final bool disabled;
  final String? createdAt;

  const HvInvite({
    required this.id,
    required this.code,
    this.note,
    required this.maxUses,
    required this.useCount,
    required this.disabled,
    this.createdAt,
  });

  factory HvInvite.fromJson(Map<String, dynamic> json) {
    return HvInvite(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      note: json['note'] as String?,
      maxUses: (json['max_uses'] as num?)?.toInt() ?? 1,
      useCount: (json['use_count'] as num?)?.toInt() ?? 0,
      disabled: json['disabled'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  HvInvite copyWith({bool? disabled}) => HvInvite(
    id: id,
    code: code,
    note: note,
    maxUses: maxUses,
    useCount: useCount,
    disabled: disabled ?? this.disabled,
    createdAt: createdAt,
  );

  bool get usedUp => useCount >= maxUses;

  String get statusLabel {
    if (disabled) return 'Disabled';
    if (usedUp) return 'Used up';
    return 'Active';
  }
}
