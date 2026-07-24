import 'package:dio/dio.dart';

import 'models/mcp_registry_server.dart';

/// Thrown for any non-2xx response or transport failure talking to the
/// public MCP Registry API.
class McpRegistryApiException implements Exception {
  final String message;
  final int? statusCode;

  const McpRegistryApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Client for the official MCP Registry REST API
/// (https://registry.modelcontextprotocol.io), the public API that backs
/// GitHub's MCP Registry (github.com/mcp). Unlike [HyperVaultClient]-based
/// services, this talks directly to a third-party public API with no
/// authentication — reads are unauthenticated per the registry's own API,
/// so this owns its own bare [Dio] instance rather than routing through
/// HyperVault.
class McpRegistryApiService {
  static const String baseUrl = 'https://registry.modelcontextprotocol.io';
  static const int defaultPageSize = 30;

  final Dio _dio;

  McpRegistryApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                validateStatus: (_) => true,
              ),
            );

  /// `GET /v0.1/servers` — one page of results. Pass [cursor] (from the
  /// previous page's [McpRegistryPage.nextCursor]) to load the next page;
  /// omit it for the first page. [search] does a case-insensitive substring
  /// match against server name/description server-side.
  Future<McpRegistryPage> listServers({
    String? search,
    String? cursor,
    int limit = defaultPageSize,
  }) async {
    final response = await _get('/v0.1/servers', query: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': limit,
    });
    return McpRegistryPage.fromJson(response);
  }

  /// `GET /v0.1/servers/{name}/versions/{version}` — full detail for one
  /// server version (used to resolve the latest version's `packages`/
  /// `remotes` before install, since list results may omit some fields).
  Future<McpRegistryServer> getServerVersion(
    String name, {
    String version = 'latest',
  }) async {
    final response = await _get(
      '/v0.1/servers/${Uri.encodeComponent(name)}/versions/$version',
    );
    return McpRegistryServer.fromJson(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    late final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(path, queryParameters: query);
    } on DioException catch (e) {
      throw McpRegistryApiException(
        e.message ?? 'Network error contacting the MCP registry.',
      );
    }

    final status = response.statusCode ?? 0;
    final data = response.data;
    if (status >= 200 && status < 300) {
      if (data is Map<String, dynamic>) return data;
      throw const McpRegistryApiException(
        'The MCP registry returned an unexpected response.',
      );
    }

    String message = 'MCP registry request failed ($status).';
    if (data is Map<String, dynamic>) {
      final err = data['error'] ?? data['message'];
      if (err is String && err.isNotEmpty) message = err;
    }
    throw McpRegistryApiException(message, statusCode: status);
  }
}
