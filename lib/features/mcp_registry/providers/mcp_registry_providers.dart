import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/hypervault_providers.dart';
import '../../chat/data/models/mcp_integration.dart';
import '../../chat/providers/chat_mcp_providers.dart';
import '../../hv_tools/providers/hv_tools_providers.dart';
import '../data/mcp_oauth_service.dart';
import '../data/mcp_registry_api_service.dart';
import '../data/mcp_registry_header_resolver.dart';
import '../data/models/mcp_registry_server.dart';

final mcpRegistryApiServiceProvider = Provider<McpRegistryApiService>((ref) {
  return McpRegistryApiService();
});

final mcpOAuthServiceProvider = Provider<McpOAuthService>((ref) {
  return McpOAuthService();
});

/// Where a registry install actually landed, so the UI can label the result
/// ("Added to chat" vs. "Added to HyperVault toolkit").
enum McpRegistryInstallTarget { onDevice, hyperVault }

class McpRegistryInstallResult {
  final McpRegistryInstallTarget target;
  const McpRegistryInstallResult(this.target);
}

class McpRegistryInstallException implements Exception {
  final String message;
  const McpRegistryInstallException(this.message);

  @override
  String toString() => message;
}

/// Decides, per server.json, which surface a registry entry installs into,
/// then performs the install. Product decisions this encodes:
///
/// - stdio-only servers (no `remotes`) never reach here — the browse screen
///   disables "Install" for them directly (mobile can't spawn local
///   processes; see [McpRegistryServer.hasStdioOnly]).
/// - a remote that declares static secret headers in server.json (a pasted
///   API key/token) installs on-device, via [ChatMcpConfigNotifier] —
///   that's a "compatible" server per the product call: no interactive auth
///   needed, the on-device MCP client can just attach the header.
/// - a remote that declares no headers but rejects an anonymous request
///   needs OAuth. The PKCE flow itself runs on-device
///   ([McpOAuthService]), but the resulting bearer token is handed to
///   HyperVault's `/api/mcp-servers` as an `Authorization` header rather
///   than kept on-device — HyperVault already stores API-key/bearer headers
///   securely for that endpoint (and for `/api/backends`), and the on-device
///   MCP client has no token-refresh story of its own.
class McpRegistryInstallService {
  final Ref _ref;
  const McpRegistryInstallService(this._ref);

  Future<McpRegistryInstallResult> install(
    McpRegistryServer server, {
    Map<String, String> headerValues = const {},
  }) async {
    final remote = server.primaryRemote;
    if (remote == null) {
      throw const McpRegistryInstallException(
        'This server has no installable remote endpoint.',
      );
    }
    final label = server.displayName;

    if (remote.hasDeclaredSecretHeaders) {
      final Map<String, String> headers;
      try {
        headers = resolveMcpHeaderValues(remote.headers, headerValues);
      } on McpRegistryHeaderException catch (e) {
        throw McpRegistryInstallException(e.message);
      }
      await _installOnDevice(label: label, remote: remote, headers: headers);
      return const McpRegistryInstallResult(McpRegistryInstallTarget.onDevice);
    }

    final needsAuth = await _ref
        .read(mcpOAuthServiceProvider)
        .requiresAuth(remote.url);
    if (!needsAuth) {
      await _installOnDevice(label: label, remote: remote, headers: null);
      return const McpRegistryInstallResult(McpRegistryInstallTarget.onDevice);
    }

    await _installViaOAuth(server: server, label: label, remote: remote);
    return const McpRegistryInstallResult(McpRegistryInstallTarget.hyperVault);
  }

  Future<void> _installOnDevice({
    required String label,
    required McpRegistryRemote remote,
    Map<String, String>? headers,
  }) async {
    try {
      await _ref.read(chatMcpConfigProvider.notifier).installIntegration(
            McpIntegration(
              type: McpIntegrationType.ephemeralMcp,
              serverLabel: label,
              serverUrl: remote.url,
              headers: headers,
            ),
          );
    } catch (e) {
      throw McpRegistryInstallException('Could not connect to $label: $e');
    }
  }

  Future<void> _installViaOAuth({
    required McpRegistryServer server,
    required String label,
    required McpRegistryRemote remote,
  }) async {
    final oauth = await _ref
        .read(mcpOAuthServiceProvider)
        .authorize(remoteUrl: remote.url, serverName: label);

    final maxServers =
        _ref.read(capabilitiesProvider).value?.limits.maxMcpServers ?? 20;
    try {
      await _ref.read(hvToolsProvider.notifier).addServerFromRegistry(
            url: remote.url,
            name: label,
            registryId: server.name,
            headers: {'Authorization': 'Bearer ${oauth.accessToken}'},
            maxServers: maxServers,
          );
    } catch (e) {
      throw McpRegistryInstallException(
        'Signed in, but HyperVault could not save $label: $e',
      );
    }
  }
}

final mcpRegistryInstallServiceProvider =
    Provider<McpRegistryInstallService>((ref) {
  return McpRegistryInstallService(ref);
});

/// Paginated browse state for [McpRegistryScreen] — "Loaded in pages" per
/// the product ask, mirroring the registry API's own cursor pagination
/// rather than fetching everything at once.
class McpRegistryBrowseState {
  final String query;
  final List<McpRegistryServer> servers;
  final String? nextCursor;
  final bool loading;
  final bool loadingMore;
  final String? error;

  const McpRegistryBrowseState({
    this.query = '',
    this.servers = const [],
    this.nextCursor,
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  McpRegistryBrowseState copyWith({
    String? query,
    List<McpRegistryServer>? servers,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) {
    return McpRegistryBrowseState(
      query: query ?? this.query,
      servers: servers ?? this.servers,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class McpRegistryBrowseNotifier extends Notifier<McpRegistryBrowseState> {
  int _requestId = 0;

  @override
  McpRegistryBrowseState build() => const McpRegistryBrowseState();

  /// Loads the default/first page once, the first time the browse screen
  /// mounts — a no-op if a search has already run.
  Future<void> loadInitial() {
    if (state.servers.isNotEmpty || state.loading) return Future.value();
    return search('');
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final requestId = ++_requestId;
    state = state.copyWith(
      query: trimmed,
      loading: true,
      clearError: true,
      clearNextCursor: true,
    );
    try {
      final page = await ref
          .read(mcpRegistryApiServiceProvider)
          .listServers(search: trimmed.isEmpty ? null : trimmed);
      if (requestId != _requestId) return;
      state = state.copyWith(
        servers: page.servers,
        nextCursor: page.nextCursor,
        loading: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      final message =
          e is McpRegistryApiException ? e.message : 'Registry search failed.';
      state = state.copyWith(loading: false, error: message);
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    final requestId = _requestId;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref
          .read(mcpRegistryApiServiceProvider)
          .listServers(
            search: state.query.isEmpty ? null : state.query,
            cursor: cursor,
          );
      if (requestId != _requestId) return;
      state = state.copyWith(
        servers: [...state.servers, ...page.servers],
        nextCursor: page.nextCursor,
        clearNextCursor: page.nextCursor == null,
        loadingMore: false,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(loadingMore: false);
    }
  }
}

final mcpRegistryBrowseProvider =
    NotifierProvider<McpRegistryBrowseNotifier, McpRegistryBrowseState>(
  McpRegistryBrowseNotifier.new,
);
