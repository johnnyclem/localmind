import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/hv_tools_api_service.dart';
import '../data/models/mcp_server_entry.dart';
import '../data/models/registry_entry.dart';
import '../data/models/toolkit_status.dart';

final hvToolsApiServiceProvider = Provider<HvToolsApiService>((ref) {
  return HvToolsApiService(ref.watch(hypervaultClientProvider));
});

McpServerEntry? _findById(List<McpServerEntry> list, String id) {
  for (final entry in list) {
    if (entry.id == id) return entry;
  }
  return null;
}

bool _sameStringSet(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  final setA = a.toSet();
  return setA.length == b.toSet().length && setA.containsAll(b);
}

/// Draft/compile state: [persisted] mirrors what the server currently has
/// (from the last list load or the last successful compile); [draft] holds
/// pending local edits to `enabled` / `disabledTools`. Add/delete/refresh hit
/// the API immediately and update both lists; only the enable toggles are
/// deferred until [HvToolsNotifier.compile].
class HvToolsState {
  final List<McpServerEntry> persisted;
  final List<McpServerEntry> draft;
  final ToolkitStatus? toolkit;
  final CompileResult? lastCompileResult;
  final bool compiling;
  final String? compileError;

  const HvToolsState({
    this.persisted = const [],
    this.draft = const [],
    this.toolkit,
    this.lastCompileResult,
    this.compiling = false,
    this.compileError,
  });

  /// Per-server dirty flags, keyed by id, for whichever field changed.
  bool get isDirty {
    if (persisted.length != draft.length) return true;
    for (final d in draft) {
      final p = _findById(persisted, d.id);
      if (p == null) return true;
      if (p.enabled != d.enabled) return true;
      if (!_sameStringSet(p.disabledTools, d.disabledTools)) return true;
    }
    return false;
  }

  int get pendingChangeCount {
    var count = 0;
    for (final d in draft) {
      final p = _findById(persisted, d.id);
      if (p == null ||
          p.enabled != d.enabled ||
          !_sameStringSet(p.disabledTools, d.disabledTools)) {
        count++;
      }
    }
    return count;
  }

  HvToolsState copyWith({
    List<McpServerEntry>? persisted,
    List<McpServerEntry>? draft,
    ToolkitStatus? toolkit,
    bool clearToolkit = false,
    CompileResult? lastCompileResult,
    bool? compiling,
    String? compileError,
    bool clearCompileError = false,
  }) {
    return HvToolsState(
      persisted: persisted ?? this.persisted,
      draft: draft ?? this.draft,
      toolkit: clearToolkit ? null : (toolkit ?? this.toolkit),
      lastCompileResult: lastCompileResult ?? this.lastCompileResult,
      compiling: compiling ?? this.compiling,
      compileError: clearCompileError ? null : (compileError ?? this.compileError),
    );
  }
}

class HvToolsNotifier extends AsyncNotifier<HvToolsState> {
  static const _cacheKey = 'hv_tools_servers';

  @override
  Future<HvToolsState> build() async {
    final cache = ref.watch(hyperVaultCacheProvider);
    final userId = ref.watch(authProvider).user?.id;
    final cached = cache.read(_cacheKey, userId: userId);
    if (cached is List) {
      final servers = cached
          .whereType<Map<String, dynamic>>()
          .map(McpServerEntry.fromJson)
          .toList();
      unawaited(_refresh());
      return HvToolsState(persisted: servers, draft: List.of(servers));
    }
    return _fetch();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _fetch();
      state = AsyncData(fresh);
    } catch (e) {
      Log.warning('[hv-tools] revalidate failed: $e');
    }
  }

  Future<HvToolsState> _fetch() async {
    final api = ref.read(hvToolsApiServiceProvider);
    final servers = await api.fetchServers();
    ToolkitStatus? toolkit;
    try {
      toolkit = await api.fetchToolkit();
    } catch (e) {
      Log.warning('[hv-tools] toolkit status fetch failed: $e');
    }
    await _persistCache(servers);
    return HvToolsState(
      persisted: servers,
      draft: List.of(servers),
      toolkit: toolkit,
    );
  }

  Future<void> _persistCache(List<McpServerEntry> servers) async {
    final cache = ref.read(hyperVaultCacheProvider);
    final userId = ref.read(authProvider).user?.id;
    await cache.put(
      _cacheKey,
      servers.map((s) => s.toJson()).toList(),
      userId: userId,
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  // ---- Draft-only mutations (no network call) ----

  void toggleServerEnabled(String id, bool enabled) {
    final current = state.value;
    if (current == null) return;
    final draft = current.draft
        .map((s) => s.id == id ? s.copyWith(enabled: enabled) : s)
        .toList();
    state = AsyncData(current.copyWith(draft: draft));
  }

  void toggleToolDisabled(String serverId, String toolName, bool disabled) {
    final current = state.value;
    if (current == null) return;
    final draft = current.draft.map((s) {
      if (s.id != serverId) return s;
      final set = s.disabledTools.toSet();
      if (disabled) {
        set.add(toolName);
      } else {
        set.remove(toolName);
      }
      return s.copyWith(disabledTools: set.toList());
    }).toList();
    state = AsyncData(current.copyWith(draft: draft));
  }

  void disableAllTools(String serverId) {
    final current = state.value;
    if (current == null) return;
    final draft = current.draft.map((s) {
      if (s.id != serverId) return s;
      return s.copyWith(disabledTools: s.tools.map((t) => t.name).toList());
    }).toList();
    state = AsyncData(current.copyWith(draft: draft));
  }

  void enableAllTools(String serverId) {
    final current = state.value;
    if (current == null) return;
    final draft = current.draft.map((s) {
      if (s.id != serverId) return s;
      return s.copyWith(disabledTools: const []);
    }).toList();
    state = AsyncData(current.copyWith(draft: draft));
  }

  void undo() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        draft: List.of(current.persisted),
        clearCompileError: true,
      ),
    );
  }

  // ---- Network-backed mutations ----

  Future<void> addServer({
    required String url,
    String? name,
    Map<String, String>? headers,
    int maxServers = 20,
  }) async {
    final current = state.value ?? const HvToolsState();
    if (current.persisted.length >= maxServers) {
      throw HyperVaultApiException(
        message:
            'You have reached the limit of $maxServers MCP servers. Remove one before adding another.',
      );
    }
    final api = ref.read(hvToolsApiServiceProvider);
    final created = await api.addServer(url: url, name: name, headers: headers);
    final persisted = [...current.persisted, created];
    final draft = [...current.draft, created];
    state = AsyncData(
      current.copyWith(
        persisted: persisted,
        draft: draft,
        toolkit: current.toolkit?.copyWith(stale: true),
      ),
    );
    await _persistCache(persisted);
  }

  Future<void> addServerFromRegistry({
    required String url,
    required String name,
    required String registryId,
    int maxServers = 20,
  }) async {
    final current = state.value ?? const HvToolsState();
    if (current.persisted.length >= maxServers) {
      throw HyperVaultApiException(
        message:
            'You have reached the limit of $maxServers MCP servers. Remove one before adding another.',
      );
    }
    final api = ref.read(hvToolsApiServiceProvider);
    final created = await api.addServer(
      url: url,
      name: name,
      registryId: registryId,
    );
    final persisted = [...current.persisted, created];
    final draft = [...current.draft, created];
    state = AsyncData(
      current.copyWith(
        persisted: persisted,
        draft: draft,
        toolkit: current.toolkit?.copyWith(stale: true),
      ),
    );
    await _persistCache(persisted);
  }

  Future<void> deleteServer(String id) async {
    final current = state.value;
    if (current == null) return;
    final api = ref.read(hvToolsApiServiceProvider);
    await api.deleteServer(id);
    final persisted = current.persisted.where((s) => s.id != id).toList();
    final draft = current.draft.where((s) => s.id != id).toList();
    state = AsyncData(
      current.copyWith(
        persisted: persisted,
        draft: draft,
        toolkit: current.toolkit?.copyWith(stale: true),
      ),
    );
    await _persistCache(persisted);
  }

  Future<void> refreshServer(String id) async {
    final current = state.value;
    if (current == null) return;
    final existing = _findById(current.persisted, id) ?? _findById(current.draft, id);
    if (existing == null) return;
    final api = ref.read(hvToolsApiServiceProvider);
    final refreshed = await api.refreshServer(id, existing);

    McpServerEntry apply(McpServerEntry s) {
      if (s.id != id) return s;
      return s.copyWith(
        tools: refreshed.tools,
        disabledTools: refreshed.disabledTools,
        introspectedAt: refreshed.introspectedAt,
      );
    }

    final persisted = current.persisted.map(apply).toList();
    final draft = current.draft.map(apply).toList();
    state = AsyncData(current.copyWith(persisted: persisted, draft: draft));
    await _persistCache(persisted);
  }

  Future<void> compile() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(compiling: true, clearCompileError: true),
    );
    final api = ref.read(hvToolsApiServiceProvider);
    try {
      final result = await api.compile(current.draft);
      final persisted = List.of(current.draft);
      state = AsyncData(
        (state.value ?? current).copyWith(
          persisted: persisted,
          draft: persisted,
          compiling: false,
          lastCompileResult: result,
          clearCompileError: true,
        ),
      );
      await _persistCache(persisted);
      try {
        final toolkit = await api.fetchToolkit();
        final latest = state.value;
        if (latest != null) {
          state = AsyncData(latest.copyWith(toolkit: toolkit));
        }
      } catch (e) {
        Log.warning('[hv-tools] post-compile toolkit refresh failed: $e');
      }
    } on HyperVaultApiException catch (e) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(compiling: false, compileError: e.message));
      rethrow;
    } catch (e) {
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(compiling: false, compileError: e.toString()),
      );
      rethrow;
    }
  }
}

final hvToolsProvider = AsyncNotifierProvider<HvToolsNotifier, HvToolsState>(
  HvToolsNotifier.new,
);

// ---- Registry search ----

class RegistrySearchState {
  final String query;
  final bool loading;
  final List<RegistryServerEntry> servers;
  final List<RegistryServerEntry> suggested;
  final String? error;

  const RegistrySearchState({
    this.query = '',
    this.loading = false,
    this.servers = const [],
    this.suggested = const [],
    this.error,
  });
}

class RegistrySearchNotifier extends Notifier<RegistrySearchState> {
  int _requestId = 0;

  @override
  RegistrySearchState build() => const RegistrySearchState();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final requestId = ++_requestId;
    state = RegistrySearchState(
      query: trimmed,
      loading: true,
      servers: state.servers,
      suggested: state.suggested,
    );
    final api = ref.read(hvToolsApiServiceProvider);
    try {
      final result = await api.searchRegistry(trimmed);
      if (requestId != _requestId) return;
      state = RegistrySearchState(
        query: trimmed,
        loading: false,
        servers: result.servers,
        suggested: result.suggested,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      final message = e is HyperVaultApiException
          ? e.message
          : 'Registry search failed.';
      state = RegistrySearchState(
        query: trimmed,
        loading: false,
        servers: const [],
        suggested: state.suggested,
        error: message,
      );
    }
  }

  Future<void> loadSuggested() => search('');

  void clear() {
    _requestId++;
    state = const RegistrySearchState();
  }
}

final registrySearchProvider =
    NotifierProvider<RegistrySearchNotifier, RegistrySearchState>(
      RegistrySearchNotifier.new,
    );
