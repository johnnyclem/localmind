import '../../../core/network/hypervault_client.dart';
import 'models/vault_connection.dart';

/// Thin typed wrapper around [HyperVaultClient] for the Vault Graph's edges
/// (mobile PRD M4, T-M4-02). Mirrors the shape of
/// `lib/features/vault/data/vault_api_service.dart`.
class VaultGraphApiService {
  final HyperVaultClient _client;

  VaultGraphApiService(this._client);

  /// `GET /api/connections` -> `{connections, memory_links,
  /// memory_artifact_links}`. Only `connections` (artifact-artifact edges)
  /// is used in v1 per the mobile PRD; the other two arrays are ignored.
  Future<List<VaultConnection>> fetchConnections() async {
    final json = await _client.get<Map<String, dynamic>>('/api/connections');
    final items = (json['connections'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(VaultConnection.fromJson)
        .toList();
  }
}
