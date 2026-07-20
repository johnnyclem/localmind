import '../../hypervault/data/hypervault_api_client.dart';
import 'models/hv_backend.dart';

/// Typed wrapper over `GET/POST/PATCH/DELETE /api/backends` (see
/// docs/mobile/prd/api-contract.md and prd/10-byo-llm-backends.md). Talks
/// only through [HyperVaultApiClient] — never constructs its own Dio — so
/// auth headers, retries, and `{error}` normalization stay centralized
/// there.
class HyperVaultBackendsService {
  final HyperVaultApiClient _client;

  const HyperVaultBackendsService(this._client);

  Future<HvBackendsSnapshot> list() async {
    final json = await _client.get('/api/backends');
    final backends = ((json['backends'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => HvBackend.fromJson(e.cast<String, dynamic>()))
        .toList();
    final providers = ((json['providers'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => HvProviderSpec.fromJson(e.cast<String, dynamic>()))
        .toList();
    return HvBackendsSnapshot(backends: backends, providers: providers);
  }

  /// Connects a new backend. `maxDuration 60` server-side — it runs a live
  /// one-turn connection test unless [skipTest] is set.
  Future<HvBackendMutationResult> create({
    required String provider,
    String? name,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    String? embeddingModel,
    bool skipTest = false,
  }) async {
    final json = await _client.post(
      '/api/backends',
      body: {
        'provider': provider,
        if (name != null && name.isNotEmpty) 'name': name,
        if (apiKey != null && apiKey.isNotEmpty) 'api_key': apiKey,
        if (baseUrl != null && baseUrl.isNotEmpty) 'base_url': baseUrl,
        if (defaultModel != null && defaultModel.isNotEmpty)
          'default_model': defaultModel,
        if (embeddingModel != null && embeddingModel.isNotEmpty)
          'embedding_model': embeddingModel,
        if (skipTest) 'skip_test': true,
      },
    );
    return _mutationResult(json);
  }

  /// Edits a connected backend in place. The provider is fixed server-side.
  /// [name]/[baseUrl]/[defaultModel] are always sent (an empty string clears
  /// the optional ones); pass `embeddingModel: null` to leave it untouched
  /// (e.g. the field isn't shown for this provider) or `''` to clear it. A
  /// blank/omitted [apiKey] keeps the currently stored key.
  Future<HvBackendMutationResult> update({
    required String id,
    required String name,
    required String baseUrl,
    required String defaultModel,
    String? embeddingModel,
    String? apiKey,
    bool skipTest = false,
  }) async {
    final json = await _client.patch(
      '/api/backends',
      body: {
        'id': id,
        'name': name,
        'base_url': baseUrl,
        'default_model': defaultModel,
        'embedding_model': ?embeddingModel,
        if (apiKey != null && apiKey.isNotEmpty) 'api_key': apiKey,
        if (skipTest) 'skip_test': true,
      },
    );
    return _mutationResult(json);
  }

  Future<String> delete(String id) async {
    final json = await _client.delete('/api/backends', body: {'id': id});
    return json['message']?.toString() ?? 'Backend disconnected.';
  }

  HvBackendMutationResult _mutationResult(Map<String, dynamic> json) {
    final backend =
        (json['backend'] as Map?)?.cast<String, dynamic>() ?? const {};
    return HvBackendMutationResult(
      backend: HvBackend.fromJson(backend),
      message: json['message']?.toString() ?? 'Saved.',
    );
  }
}
