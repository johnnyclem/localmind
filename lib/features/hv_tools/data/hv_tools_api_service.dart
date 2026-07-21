import 'package:dio/dio.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/network/hypervault_client.dart';
import 'models/mcp_server_entry.dart';
import 'models/registry_entry.dart';
import 'models/toolkit_status.dart';

/// Typed wrapper around [HyperVaultClient] for HyperVault's server-side MCP
/// registry + toolkit compiler (`/api/mcp-servers`, `/api/toolkits*`,
/// `/api/registry/search`). This is a *different* concept from
/// lib/features/mcp/, which manages MCP servers the on-device chat talks to
/// directly — these are servers HyperVault's backend introspects and
/// compiles into a shared toolkit for `POST /api/chat`'s `use_tools` flag.
class HvToolsApiService {
  final HyperVaultClient _client;

  HvToolsApiService(this._client);

  Future<List<McpServerEntry>> fetchServers() async {
    final json = await _client.get<Map<String, dynamic>>('/api/mcp-servers');
    final list = json['servers'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(McpServerEntry.fromJson)
        .toList();
  }

  /// `POST /api/mcp-servers` performs live introspection server-side and can
  /// take up to 60s, longer than [HyperVaultClient]'s default receive
  /// timeout — this bypasses the generic `post<T>` helper and talks to
  /// `client.dio` directly with an extended timeout, per the foundation's
  /// documented escape hatch.
  Future<McpServerEntry> addServer({
    required String url,
    String? name,
    Map<String, String>? headers,
    String? registryId,
  }) async {
    final data = <String, dynamic>{
      'url': url,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (headers != null && headers.isNotEmpty) 'headers': headers,
      if (registryId != null && registryId.isNotEmpty)
        'registry_id': registryId,
    };
    final body = await _longRequest(
      '/api/mcp-servers',
      data: data,
      receiveTimeout: const Duration(seconds: 65),
    );
    final serverJson = body['server'];
    if (serverJson is! Map<String, dynamic>) {
      throw const HyperVaultApiException(
        message: 'HyperVault did not return the created MCP server.',
      );
    }
    return McpServerEntry.fromJson(serverJson);
  }

  Future<McpServerEntry> updateServer(
    String id, {
    String? name,
    bool? enabled,
    List<String>? disabledTools,
    Map<String, String>? headers,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (enabled != null) 'enabled': enabled,
      if (disabledTools != null) 'disabled_tools': disabledTools,
      if (headers != null) 'headers': headers,
    };
    final json = await _client.patch<Map<String, dynamic>>(
      '/api/mcp-servers/$id',
      data: data,
    );
    final serverJson = json['server'];
    if (serverJson is! Map<String, dynamic>) {
      throw const HyperVaultApiException(
        message: 'HyperVault did not return the updated MCP server.',
      );
    }
    return McpServerEntry.fromJson(serverJson);
  }

  Future<void> deleteServer(String id) async {
    await _client.delete<Map<String, dynamic>>('/api/mcp-servers/$id');
  }

  /// Re-introspects one server's tool list. [existing] supplies the fields
  /// the refresh response doesn't repeat (id/name/url/hasAuth/enabled) so
  /// callers get a full [McpServerEntry] back.
  Future<McpServerEntry> refreshServer(
    String id,
    McpServerEntry existing,
  ) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/mcp-servers/$id/refresh',
    );
    final rawTools = json['tools'];
    final rawDisabled = json['disabled_tools'] ?? json['disabledTools'];
    return existing.copyWith(
      tools: rawTools is List
          ? rawTools
                .whereType<Map<String, dynamic>>()
                .map(McpTool.fromJson)
                .toList()
          : existing.tools,
      disabledTools: rawDisabled is List
          ? rawDisabled.map((e) => e.toString()).toList()
          : existing.disabledTools,
      introspectedAt: parseHvDate(
        json['introspected_at'] ?? json['introspectedAt'],
      ),
    );
  }

  Future<ToolkitStatus> fetchToolkit() async {
    final json = await _client.get<Map<String, dynamic>>('/api/toolkits');
    return ToolkitStatus.fromJson(json);
  }

  /// `POST /api/toolkits/compile` can run up to 300s — bypasses the generic
  /// `post<T>` helper for the same reason as [addServer].
  Future<CompileResult> compile(List<McpServerEntry> draftServers) async {
    final data = {
      'servers': draftServers.map((s) => s.toCompilePayload()).toList(),
    };
    final body = await _longRequest(
      '/api/toolkits/compile',
      data: data,
      receiveTimeout: const Duration(seconds: 305),
    );
    return CompileResult.fromJson(body);
  }

  Future<RegistrySearchResponse> searchRegistry(String query) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/api/registry/search',
      query: {'q': query},
    );
    return RegistrySearchResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> _longRequest(
    String path, {
    required Object? data,
    required Duration receiveTimeout,
  }) async {
    late final Response<dynamic> response;
    try {
      response = await _client.dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: 'POST', receiveTimeout: receiveTimeout),
      );
    } on DioException catch (e) {
      throw HyperVaultApiException(
        message: e.message ?? 'Network error contacting HyperVault.',
      );
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      final body = response.data;
      return body is Map<String, dynamic> ? body : <String, dynamic>{};
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
