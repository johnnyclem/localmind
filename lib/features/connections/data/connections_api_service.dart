import '../../../core/network/hypervault_client.dart';
import 'models/connection.dart';

/// Thin typed wrapper around [HyperVaultClient] for Connections (mobile PRD
/// M5, T-M5-01/02/08). Mirrors the shape of
/// `lib/features/vault/data/vault_api_service.dart`.
class ConnectionsApiService {
  final HyperVaultClient _client;

  ConnectionsApiService(this._client);

  /// `GET /api/connections` -> `{ connections, memory_links,
  /// memory_artifact_links }`. `memory_links`/`memory_artifact_links` are
  /// intentionally left unparsed — v1 connect scope is artifact-to-artifact
  /// only.
  Future<ConnectionsResponse> fetchConnections() async {
    final json = await _client.get<Map<String, dynamic>>('/api/connections');
    return ConnectionsResponse.fromJson(json);
  }

  /// `POST /api/connections` `{ source, target }` -> `{ connected: [fromId,
  /// toId], message }`. [source]/[target] are artifact slugs for v1.
  /// Idempotent server-side — safe to retry.
  Future<List<String>> connect({
    required String source,
    required String target,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/connections',
      data: {'source': source, 'target': target},
    );
    final connected = (json['connected'] as List?) ?? const [];
    return connected.map((e) => e.toString()).toList();
  }

  /// `DELETE /api/connections` `{ id }` -> `{ deleted: id }`. [id] is a
  /// `connections` row id (from [fetchConnections]), not an artifact id.
  Future<void> disconnect(String id) async {
    await _client.delete<Map<String, dynamic>>(
      '/api/connections',
      data: {'id': id},
    );
  }
}
