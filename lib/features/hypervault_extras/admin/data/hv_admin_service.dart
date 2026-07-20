import '../../../hypervault/data/hypervault_api_client.dart';
import 'models/hv_invite.dart';

/// Typed wrapper over the owner-only `/api/admin/*` routes (spec
/// docs/mobile/prd/15-admin.md). Every mutating route already exists and is
/// bearer + admin-gated server-side; there is no `GET` list endpoint for
/// invites/waitlist/accounts, so this only exposes the create/mutate/delete
/// actions the contract defines — no invented list calls.
class HvAdminService {
  final HyperVaultApiClient _client;

  const HvAdminService(this._client);

  Future<void> updateAccount(
    String accountId, {
    String? plan,
    String? displayName,
    bool? approved,
  }) async {
    await _client.patch(
      '/api/admin/accounts/$accountId',
      body: {
        'plan': ?plan,
        if (displayName != null && displayName.trim().isNotEmpty)
          'displayName': displayName.trim(),
        'approved': ?approved,
      },
    );
  }

  Future<void> deleteAccount(String accountId) async {
    await _client.delete('/api/admin/accounts/$accountId');
  }

  Future<HvInvite> createInvite({int? maxUses, String? note}) async {
    final json = await _client.post(
      '/api/admin/invites',
      body: {
        'maxUses': ?maxUses,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return HvInvite.fromJson((json['invite'] as Map).cast<String, dynamic>());
  }

  Future<HvInvite> setInviteDisabled(String inviteId, bool disabled) async {
    final json = await _client.patch(
      '/api/admin/invites/$inviteId',
      body: {'disabled': disabled},
    );
    return HvInvite.fromJson((json['invite'] as Map).cast<String, dynamic>());
  }

  Future<void> deleteInvite(String inviteId) async {
    await _client.delete('/api/admin/invites/$inviteId');
  }

  Future<void> removeFromWaitlist(String waitlistUserId) async {
    await _client.delete('/api/admin/waitlist/$waitlistUserId');
  }
}
