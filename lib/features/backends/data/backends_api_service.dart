import 'package:dio/dio.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/network/hypervault_client.dart';
import 'models/backend.dart';

/// Result of a create/update call: the persisted [backend] plus the
/// server's verbatim success `message` (shown in a SnackBar).
class BackendMutationResult {
  final Backend backend;
  final String message;

  const BackendMutationResult({required this.backend, required this.message});
}

/// Thin typed wrapper around [HyperVaultClient] for `/api/backends`,
/// mirroring `ServerApiService`'s role for on-device servers.
///
/// `POST`/`PATCH /api/backends` run a live connection test server-side and
/// can take up to 60s, well past [HyperVaultClient]'s default 30s receive
/// timeout — those two calls go through [_sendWithExtendedTimeout], which
/// hits the same [HyperVaultClient.dio] instance (so auth injection, base
/// URL resolution, and retry/redirect interceptors still apply) but with a
/// longer per-call timeout, and replicates the client's `{error}`
/// normalization since that's private to [HyperVaultClient].
class BackendsApiService {
  final HyperVaultClient _client;

  BackendsApiService(this._client);

  Future<BackendsListResult> fetchBackends() async {
    final json = await _client.get<Map<String, dynamic>>('/api/backends');
    return BackendsListResult.fromJson(json);
  }

  Future<BackendMutationResult> createBackend({
    required String provider,
    String? name,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    String? embeddingModel,
    bool? skipTest,
  }) async {
    final data = <String, dynamic>{'provider': provider};
    _putIfNotEmpty(data, 'name', name);
    _putIfNotEmpty(data, 'api_key', apiKey);
    _putIfNotEmpty(data, 'base_url', baseUrl);
    _putIfNotEmpty(data, 'default_model', defaultModel);
    _putIfNotEmpty(data, 'embedding_model', embeddingModel);
    if (skipTest != null) data['skip_test'] = skipTest;

    final json = await _sendWithExtendedTimeout('POST', '/api/backends', data);
    return _resultFrom(json, fallbackMessage: 'Backend connected.');
  }

  /// A blank/omitted [apiKey] means "keep the currently stored key" — the
  /// caller must not pass an empty string, only `null` or a real value.
  Future<BackendMutationResult> updateBackend({
    required String id,
    String? name,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    String? embeddingModel,
    bool? skipTest,
  }) async {
    final data = <String, dynamic>{'id': id};
    _putIfNotEmpty(data, 'name', name);
    _putIfNotEmpty(data, 'api_key', apiKey);
    _putIfNotEmpty(data, 'base_url', baseUrl);
    _putIfNotEmpty(data, 'default_model', defaultModel);
    _putIfNotEmpty(data, 'embedding_model', embeddingModel);
    if (skipTest != null) data['skip_test'] = skipTest;

    final json = await _sendWithExtendedTimeout('PATCH', '/api/backends', data);
    return _resultFrom(json, fallbackMessage: 'Backend updated.');
  }

  Future<String> deleteBackend(String id) async {
    final json = await _client.delete<Map<String, dynamic>>(
      '/api/backends',
      data: {'id': id},
    );
    return json['message'] as String? ?? 'Backend removed.';
  }

  void _putIfNotEmpty(Map<String, dynamic> data, String key, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      data[key] = value.trim();
    }
  }

  BackendMutationResult _resultFrom(
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    final backendJson = json['backend'] as Map<String, dynamic>?;
    if (backendJson == null) {
      throw const HyperVaultApiException(
        message: 'HyperVault did not return the saved backend.',
      );
    }
    return BackendMutationResult(
      backend: Backend.fromJson(backendJson),
      message: json['message'] as String? ?? fallbackMessage,
    );
  }

  Future<Map<String, dynamic>> _sendWithExtendedTimeout(
    String method,
    String path,
    Map<String, dynamic> data,
  ) async {
    late final Response<dynamic> response;
    try {
      response = await _client.dio.request<dynamic>(
        path,
        data: data,
        options: Options(
          method: method,
          receiveTimeout: const Duration(seconds: 65),
          sendTimeout: const Duration(seconds: 65),
        ),
      );
    } on DioException catch (e) {
      throw HyperVaultApiException(
        message: e.message ?? 'Network error contacting HyperVault.',
      );
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return response.data as Map<String, dynamic>;
    }
    throw _errorFor(status, response.data);
  }

  HyperVaultApiException _errorFor(int status, dynamic body) {
    String message = 'Request failed ($status).';
    String? code;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is String && err.isNotEmpty) message = err;
      final c = body['code'];
      if (c is String) code = c;
    } else if (body is String && body.isNotEmpty) {
      message = body;
    }
    return HyperVaultApiException(
      statusCode: status,
      message: message,
      code: code,
    );
  }
}
