import '../../hypervault/data/hypervault_api_client.dart';
import '../../hypervault/data/models/hv_api_error.dart';
import 'models/hv_mcp_compile_outcome.dart';
import 'models/hv_mcp_refresh_result.dart';
import 'models/hv_mcp_server.dart';
import 'models/hv_mcp_toolkit_status.dart';
import 'models/hv_registry_server.dart';

/// Friendly copy for the `CompileError` codes the compile route can return.
/// The shared [HyperVaultApiClient] only surfaces the JSON body's `error`
/// field (which the compile route puts the machine code in, not `message`),
/// so map the codes we know about here rather than showing a raw slug.
const Map<String, String> _compileErrorMessages = {
  'no_enabled_tools': 'No enabled MCP servers — add or enable one first.',
  'all_servers_unreachable':
      'None of your enabled MCP servers could be reached right now. Check '
      'the URLs and try again.',
};

/// Result of `POST /api/mcp-servers` — the connected server plus the
/// server's human-readable confirmation message.
class HvAddServerResult {
  final HvMcpServer server;
  final String message;

  const HvAddServerResult({required this.server, required this.message});
}

/// Typed wrapper over [HyperVaultApiClient] for the MCP servers + toolkits
/// endpoints (spec docs/mobile/prd/11-mcp-tools.md). Tool dispatch itself is
/// server-side (`POST /api/chat` `use_tools`) — this only manages the
/// registry of connected servers and compiles the toolkit.
class HvMcpService {
  final HyperVaultApiClient _client;

  const HvMcpService(this._client);

  Future<List<HvMcpServer>> listServers() async {
    final json = await _client.get('/api/mcp-servers');
    return ((json['servers'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => HvMcpServer.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<HvAddServerResult> addServer({
    required String url,
    String? name,
    Map<String, String>? headers,
    String? registryId,
  }) async {
    final json = await _client.post(
      '/api/mcp-servers',
      body: {
        'url': url,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (headers != null && headers.isNotEmpty) 'headers': headers,
        if (registryId != null && registryId.isNotEmpty)
          'registry_id': registryId,
      },
    );
    return HvAddServerResult(
      server: HvMcpServer.fromJson(
        (json['server'] as Map).cast<String, dynamic>(),
      ),
      message: json['message'] as String? ?? 'Connected.',
    );
  }

  /// Direct edit — rename or re-auth. Enable/disable + per-tool toggles are
  /// normally drafted client-side and persisted by [compileToolkit] in the
  /// same gesture as compilation (mirrors the web console).
  Future<HvMcpServer> updateServer(
    String id, {
    String? name,
    bool? enabled,
    List<String>? disabledTools,
    Map<String, String>? headers,
    bool clearHeaders = false,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'enabled': ?enabled,
      'disabled_tools': ?disabledTools,
    };
    if (clearHeaders) {
      body['headers'] = null;
    } else if (headers != null) {
      body['headers'] = headers;
    }
    final json = await _client.patch('/api/mcp-servers/$id', body: body);
    return HvMcpServer.fromJson(
      (json['server'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> deleteServer(String id) async {
    await _client.delete('/api/mcp-servers/$id');
  }

  Future<HvMcpRefreshResult> refreshServer(String id) async {
    final json = await _client.post('/api/mcp-servers/$id/refresh');
    return HvMcpRefreshResult.fromJson(json);
  }

  Future<HvRegistrySearchResult> searchRegistry(String query) async {
    final json = await _client.get(
      '/api/registry/search',
      query: {'q': query},
    );
    return HvRegistrySearchResult.fromJson(json);
  }

  Future<HvToolkitStatus> getToolkitStatus() async {
    final json = await _client.get('/api/toolkits');
    return HvToolkitStatus.fromJson(json);
  }

  /// Compile the draft toggle state into a toolkit. [servers] mirrors the
  /// web console's draft: `[{id, enabled, disabled_tools}]` for every server
  /// whose toggles should be persisted alongside compilation. Throws
  /// [HvCompileError] for the 422/502 outcomes the route defines, otherwise
  /// rethrows the underlying [HvApiError].
  Future<HvCompileOutcome> compileToolkit(
    List<Map<String, dynamic>> servers,
  ) async {
    try {
      final json = await _client.post(
        '/api/toolkits/compile',
        body: {'servers': servers},
      );
      return HvCompileOutcome.fromJson(json);
    } on HvApiError catch (e) {
      if (e.status == 422 || e.status == 502) {
        throw HvCompileError(
          code: e.error,
          message: _compileErrorMessages[e.error] ?? e.error,
        );
      }
      rethrow;
    }
  }
}
