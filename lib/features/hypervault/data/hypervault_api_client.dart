import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import 'models/hv_api_error.dart';

/// Typed REST client for the HyperVault API used by every feature area
/// beyond auth/capabilities/chat (vault, connections, sharing, memory,
/// git-mind, backends, MCP/tools, domains, keys, import, admin — see
/// docs/mobile/prd/api-contract.md in the hypervault repo). One place that
/// knows the base URL, injects `Authorization: Bearer <supabase jwt>`,
/// retries transient failures, and normalizes every error body
/// (`{ error: string }`) into [HvApiError].
///
/// Feature-area services should depend on this rather than talking to `Dio`
/// directly, so auth/retry/error-shape stays consistent across the app.
class HyperVaultApiClient {
  final Dio _dio;
  final String Function() _baseUrl;
  final String? Function() _accessToken;

  HyperVaultApiClient(
    this._dio, {
    required String Function() baseUrlProvider,
    required String? Function() accessTokenProvider,
  }) : _baseUrl = baseUrlProvider,
       _accessToken = accessTokenProvider;

  String get baseUrl => _baseUrl().trim().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    int attempt = 0,
  }) async {
    final token = _accessToken();
    try {
      final response = await _dio.request<dynamic>(
        '$baseUrl$path',
        queryParameters: query,
        data: body,
        options: Options(
          method: method,
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final status = response.statusCode ?? 0;
      final data = response.data;
      final json = data is Map
          ? data.cast<String, dynamic>()
          : <String, dynamic>{};

      if (status >= 200 && status < 300) {
        return json;
      }

      // Retry once on 429 with the server's hint, honoring a short jittered
      // backoff; idempotent methods only.
      if (status == 429 && method == 'GET' && attempt < 1) {
        await Future.delayed(
          Duration(milliseconds: 400 + Random().nextInt(400)),
        );
        return _send(
          method,
          path,
          query: query,
          body: body,
          attempt: attempt + 1,
        );
      }

      throw HvApiError(
        status: status,
        error: (json['error'] as String?) ?? 'Request failed ($status)',
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final json = data is Map
            ? data.cast<String, dynamic>()
            : <String, dynamic>{};
        throw HvApiError(
          status: e.response!.statusCode,
          error: (json['error'] as String?) ?? e.message ?? 'Request failed',
        );
      }
      // Transient network failure: one retry with backoff for GET only.
      if (method == 'GET' && attempt < 1) {
        await Future.delayed(
          Duration(milliseconds: 400 + Random().nextInt(400)),
        );
        return _send(
          method,
          path,
          query: query,
          body: body,
          attempt: attempt + 1,
        );
      }
      throw HvApiError(error: e.message ?? 'Network error');
    }
  }
}
