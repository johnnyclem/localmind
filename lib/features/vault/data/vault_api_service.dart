import '../../../core/network/hypervault_client.dart';
import 'models/artifact.dart';

/// Thin typed wrapper around [HyperVaultClient] for the Vault — Artifacts
/// endpoints (mobile PRD M3). Mirrors the shape of
/// `lib/features/servers/data/server_api_service.dart`.
class VaultApiService {
  final HyperVaultClient _client;

  VaultApiService(this._client);

  /// `GET /api/artifacts` — newest-first, server-capped at 200.
  Future<List<Artifact>> fetchArtifacts() async {
    final json = await _client.get<Map<String, dynamic>>('/api/artifacts');
    final items = (json['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Artifact.fromJson)
        .toList();
  }

  /// `POST /api/save`. [content] should already have been checked against
  /// `capabilities.limits.artifactBytes` by the caller.
  Future<SaveArtifactResult> saveArtifact({
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
    final body = <String, dynamic>{
      'content': content,
      'make_pwa': makePwa,
      'force_html': forceHtml,
      'visibility': visibility,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (connectTo != null && connectTo.isNotEmpty) 'connect_to': connectTo,
      if (sourcePrompt != null && sourcePrompt.trim().isNotEmpty)
        'source_prompt': sourcePrompt.trim(),
    };
    final json = await _client.post<Map<String, dynamic>>(
      '/api/save',
      data: body,
    );
    return SaveArtifactResult.fromJson(json);
  }

  /// `PATCH /api/artifacts` `{ slug, visibility }` -> `{ artifact, message }`.
  Future<Artifact?> updateVisibility({
    required String slug,
    required String visibility,
  }) async {
    final json = await _client.patch<Map<String, dynamic>>(
      '/api/artifacts',
      data: {'slug': slug, 'visibility': visibility},
    );
    final artifactJson = json['artifact'];
    if (artifactJson is Map<String, dynamic>) {
      return Artifact.fromJson(artifactJson);
    }
    return null;
  }

  /// `DELETE /api/artifacts` `{ slug }`.
  Future<void> deleteArtifact({required String slug}) async {
    await _client.delete<Map<String, dynamic>>(
      '/api/artifacts',
      data: {'slug': slug},
    );
  }

  /// `GET /api/artifacts/[slug]/source` -> `{ content }`.
  Future<String> fetchSource(String slug) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/artifacts/${Uri.encodeComponent(slug)}/source',
    );
    return json['content'] as String? ?? '';
  }

  /// `GET /api/artifacts/[slug]/feedback` -> `{ feedback }`.
  Future<String?> fetchFeedback(String slug) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/artifacts/${Uri.encodeComponent(slug)}/feedback',
    );
    return json['feedback'] as String?;
  }

  /// `POST /api/artifacts/[slug]/feedback` `{ feedback }` -> `{ feedback }`.
  /// Pass `null` to clear a previously-set reaction.
  Future<String?> postFeedback(String slug, String? feedback) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/artifacts/${Uri.encodeComponent(slug)}/feedback',
      data: {'feedback': feedback},
    );
    return json['feedback'] as String?;
  }
}
