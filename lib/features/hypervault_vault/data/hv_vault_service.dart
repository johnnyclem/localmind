import '../../hypervault/data/hypervault_api_client.dart';
import 'models/hv_artifact.dart';
import 'models/hv_connection.dart';
import 'models/hv_share.dart';

/// Typed wrapper over the vault/connections/sharing slice of the HyperVault
/// REST API (see docs/mobile/prd/api-contract.md). Talks only through
/// [HyperVaultApiClient] — never constructs its own Dio — so auth headers,
/// retries, and `{error}` normalization stay centralized there.
class HvVaultService {
  final HyperVaultApiClient _client;

  const HvVaultService(this._client);

  Future<List<HvArtifact>> listArtifacts() async {
    final json = await _client.get('/api/artifacts');
    final items = (json['items'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map((e) => HvArtifact.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Returns `(artifact json, message)` — the raw artifact patch response.
  Future<(Map<String, dynamic>, String)> setVisibility({
    required String ref,
    required String visibility,
  }) async {
    final json = await _client.patch(
      '/api/artifacts',
      body: {'id': ref, 'visibility': visibility},
    );
    final artifact = (json['artifact'] as Map?)?.cast<String, dynamic>() ?? {};
    return (artifact, json['message'] as String? ?? 'Updated.');
  }

  Future<String> deleteArtifact(String ref) async {
    final json = await _client.delete('/api/artifacts', body: {'id': ref});
    return json['message'] as String? ?? 'Deleted.';
  }

  Future<HvSaveResult> save({
    required String content,
    String? title,
    String? type,
    List<String>? tags,
    List<String>? connectTo,
    bool makePwa = true,
    bool forceHtml = false,
    String visibility = 'private',
    String? sourcePrompt,
  }) async {
    final json = await _client.post(
      '/api/save',
      body: {
        'content': content,
        if (title != null && title.isNotEmpty) 'title': title,
        if (type != null && type.isNotEmpty) 'type': type,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (connectTo != null && connectTo.isNotEmpty) 'connect_to': connectTo,
        'make_pwa': makePwa,
        'force_html': forceHtml,
        'visibility': visibility,
        if (sourcePrompt != null && sourcePrompt.isNotEmpty)
          'source_prompt': sourcePrompt,
      },
    );
    return HvSaveResult.fromJson(json);
  }

  Future<String> viewSource(String slug) async {
    final json = await _client.get('/api/artifacts/$slug/source');
    return json['content'] as String? ?? '';
  }

  Future<String?> getFeedback(String slug) async {
    final json = await _client.get('/api/artifacts/$slug/feedback');
    return json['feedback'] as String?;
  }

  Future<String?> setFeedback(String slug, String? feedback) async {
    final json = await _client.post(
      '/api/artifacts/$slug/feedback',
      body: {'feedback': feedback},
    );
    return json['feedback'] as String?;
  }

  Future<HvConnectionsData> listConnections() async {
    final json = await _client.get('/api/connections');
    return HvConnectionsData.fromJson(json);
  }

  Future<HvConnectResult> connect({
    required String source,
    required String target,
  }) async {
    final json = await _client.post(
      '/api/connections',
      body: {'source': source, 'target': target},
    );
    return HvConnectResult.fromJson(json);
  }

  Future<void> disconnect(String edgeId) async {
    await _client.delete('/api/connections', body: {'id': edgeId});
  }

  Future<List<HvShare>> listShares(String artifactRef) async {
    final json = await _client.get(
      '/api/shares',
      query: {'artifact': artifactRef},
    );
    final shares = (json['shares'] as List?) ?? const [];
    return shares
        .whereType<Map>()
        .map((e) => HvShare.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Returns the invitee summary and the server's confirmation message.
  Future<(String, String)> share({
    required String artifactRef,
    required String email,
  }) async {
    final json = await _client.post(
      '/api/shares',
      body: {'artifact': artifactRef, 'email': email},
    );
    final sharedWith = (json['shared_with'] as Map?)?.cast<String, dynamic>();
    final label = sharedWith?['display_name'] as String? ??
        sharedWith?['email'] as String? ??
        email;
    return (label, json['message'] as String? ?? 'Shared.');
  }

  Future<void> unshare(String shareId) async {
    await _client.delete('/api/shares', body: {'share_id': shareId});
  }
}
