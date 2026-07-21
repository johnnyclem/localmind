import '../../../core/network/hypervault_client.dart';
import 'models/share.dart';

/// Thin typed wrapper around [HyperVaultClient] for Sharing (mobile PRD M5,
/// T-M5-03/04/06). Mirrors the shape of
/// `lib/features/vault/data/vault_api_service.dart`. [InboundShare] ("Shared
/// with you") is read directly from Supabase instead — see
/// `views/shared_with_me_screen.dart` — since no REST list endpoint exists
/// for it.
class SharesApiService {
  final HyperVaultClient _client;

  SharesApiService(this._client);

  /// `POST /api/shares` `{ artifact, email }` -> `{ shared_with, message }`.
  /// [artifact] is a slug/id/title; the invitee must already have a
  /// HyperVault account.
  Future<ShareResult> share({
    required String artifact,
    required String email,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/shares',
      data: {'artifact': artifact, 'email': email},
    );
    return ShareResult.fromJson(json);
  }

  /// `GET /api/shares?artifact={id|slug}` (owner-only) -> `{ shares: [...]
  /// }`.
  Future<List<ArtifactShare>> fetchShares(String artifact) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/shares',
      query: {'artifact': artifact},
    );
    final items = (json['shares'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ArtifactShare.fromJson)
        .toList();
  }

  /// `DELETE /api/shares` `{ share_id }` -> `{ message }`. Used both for the
  /// owner revoking a grantee and for a grantee leaving a shared artifact.
  Future<String> revoke(String shareId) async {
    final json = await _client.delete<Map<String, dynamic>>(
      '/api/shares',
      data: {'share_id': shareId},
    );
    return json['message'] as String? ?? 'Access removed.';
  }
}
