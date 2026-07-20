/// A row from the `waitlist` table (mobile PRD M15).
///
/// `userId` doubles as the id used by `DELETE /api/admin/waitlist/[id]` —
/// the table's primary key is `user_id`, there is no separate `id` column.
class AdminWaitlistEntry {
  final String userId;
  final String? email;
  final DateTime? createdAt;

  const AdminWaitlistEntry({required this.userId, this.email, this.createdAt});

  factory AdminWaitlistEntry.fromJson(Map<String, dynamic> json) {
    return AdminWaitlistEntry(
      userId: json['user_id'] as String,
      email: json['email'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
