import '../../../core/network/hypervault_client.dart';

/// Thin typed wrapper around [HyperVaultClient] for the owner-only admin
/// mutation routes (mobile PRD M15). These are real, admin-gated REST
/// endpoints — a non-admin caller gets a [HyperVaultApiException] with
/// `statusCode == 403`; callers should show `.message` verbatim.
///
/// There are no `GET` list endpoints here on purpose — list data comes from
/// direct Supabase reads, see `admin_providers.dart`.
class AdminApiService {
  final HyperVaultClient _client;

  AdminApiService(this._client);

  /// `POST /api/admin/invites {maxUses?, note?}` -> `{invite}`.
  Future<Map<String, dynamic>> createInvite({int? maxUses, String? note}) {
    return _client.post<Map<String, dynamic>>(
      '/api/admin/invites',
      data: {
        if (maxUses != null) 'maxUses': maxUses,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  /// `PATCH /api/admin/invites/[id] {disabled}` -> `{invite}`.
  Future<Map<String, dynamic>> setInviteDisabled(String id, bool disabled) {
    return _client.patch<Map<String, dynamic>>(
      '/api/admin/invites/$id',
      data: {'disabled': disabled},
    );
  }

  /// `DELETE /api/admin/invites/[id]`.
  Future<void> deleteInvite(String id) async {
    await _client.delete<dynamic>('/api/admin/invites/$id');
  }

  /// `DELETE /api/admin/waitlist/[id]` — `[id]` is the waitlist row's
  /// `user_id`.
  Future<void> deleteWaitlistEntry(String userId) async {
    await _client.delete<dynamic>('/api/admin/waitlist/$userId');
  }

  /// `PATCH /api/admin/accounts/[id] {plan?, displayName?, approved?}`.
  Future<void> updateAccount(
    String id, {
    String? plan,
    String? displayName,
    bool? approved,
  }) async {
    await _client.patch<dynamic>(
      '/api/admin/accounts/$id',
      data: {
        if (plan != null) 'plan': plan,
        if (displayName != null) 'displayName': displayName,
        if (approved != null) 'approved': approved,
      },
    );
  }

  /// `DELETE /api/admin/accounts/[id]`. Callers must guard against
  /// self-deletion client-side; the server also rejects it.
  Future<void> deleteAccount(String id) async {
    await _client.delete<dynamic>('/api/admin/accounts/$id');
  }
}
