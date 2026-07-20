import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/storage_providers.dart';
import '../../hypervault/providers/hypervault_providers.dart';
import '../data/hv_mcp_cache.dart';
import '../data/hypervault_mcp_service.dart';
import '../data/models/hv_mcp_compile_outcome.dart';
import '../data/models/hv_mcp_server.dart';
import '../data/models/hv_mcp_toolkit_status.dart';
import '../data/models/hv_registry_server.dart';
import 'hv_mcp_console_state.dart';

final hvMcpServiceProvider = Provider<HvMcpService>((ref) {
  return HvMcpService(ref.read(hyperVaultApiClientProvider));
});

final hvMcpCacheProvider = Provider<HvMcpCache>((ref) {
  return HvMcpCache(ref.read(sharedPreferencesProvider));
});

/// The signed-in HyperVault user id, or null when signed out — the cache
/// namespace key for [HvMcpCache].
final hvMcpUserIdProvider = Provider<String?>((ref) {
  return ref.watch(hyperVaultSessionProvider)?.user.id;
});

final hvMcpConsoleProvider =
    AsyncNotifierProvider<HvMcpConsoleNotifier, HvMcpConsoleState>(
      HvMcpConsoleNotifier.new,
    );

class HvMcpConsoleNotifier extends AsyncNotifier<HvMcpConsoleState> {
  @override
  Future<HvMcpConsoleState> build() async {
    final userId = ref.watch(hvMcpUserIdProvider);
    if (userId == null) return const HvMcpConsoleState();

    final cached = ref.read(hvMcpCacheProvider).readServers(userId);
    if (cached != null) {
      // Paint the cached list instantly; revalidate quietly. A manual
      // pull-to-refresh surfaces errors explicitly.
      Future(() async {
        try {
          await refresh();
        } catch (_) {
          // Keep showing the cached list.
        }
      });
      return HvMcpConsoleState(persisted: cached, draft: cached);
    }
    final items = await _fetchAndCache(userId);
    return HvMcpConsoleState(persisted: items, draft: items);
  }

  Future<List<HvMcpServer>> _fetchAndCache(String userId) async {
    final items = await ref.read(hvMcpServiceProvider).listServers();
    await ref.read(hvMcpCacheProvider).writeServers(userId, items);
    return items;
  }

  /// Re-fetches the server list, preserving any uncommitted draft toggles on
  /// servers that still exist (dropping toggles for tools that vanished).
  Future<void> refresh() async {
    final userId = ref.read(hvMcpUserIdProvider);
    if (userId == null) return;
    final fresh = await _fetchAndCache(userId);
    final prevDraft = {
      for (final d in state.value?.draft ?? const <HvMcpServer>[]) d.id: d,
    };
    final draft = fresh.map((p) {
      final prev = prevDraft[p.id];
      if (prev == null) return p;
      final knownTools = p.toolsCache.map((t) => t.name).toSet();
      return p.copyWith(
        enabled: prev.enabled,
        disabledTools: prev.disabledTools
            .where(knownTools.contains)
            .toList(),
      );
    }).toList();
    state = AsyncData(HvMcpConsoleState(persisted: fresh, draft: draft));
  }

  void toggleServerEnabled(String id) {
    final current = state.value;
    if (current == null) return;
    _setDraft(
      current,
      current.draft
          .map((s) => s.id == id ? s.copyWith(enabled: !s.enabled) : s)
          .toList(),
    );
  }

  void toggleTool(String serverId, String toolName) {
    final current = state.value;
    if (current == null) return;
    _setDraft(
      current,
      current.draft.map((s) {
        if (s.id != serverId) return s;
        final tools = s.disabledTools.toSet();
        if (!tools.add(toolName)) tools.remove(toolName);
        return s.copyWith(disabledTools: tools.toList());
      }).toList(),
    );
  }

  void setAllTools(String serverId, {required bool enabled}) {
    final current = state.value;
    if (current == null) return;
    _setDraft(
      current,
      current.draft.map((s) {
        if (s.id != serverId) return s;
        return s.copyWith(
          disabledTools: enabled
              ? const []
              : s.toolsCache.map((t) => t.name).toList(),
        );
      }).toList(),
    );
  }

  void undo() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      HvMcpConsoleState(persisted: current.persisted, draft: current.persisted),
    );
  }

  void _setDraft(HvMcpConsoleState current, List<HvMcpServer> draft) {
    state = AsyncData(HvMcpConsoleState(persisted: current.persisted, draft: draft));
  }

  Future<HvAddServerResult> addServer({
    required String url,
    String? name,
    Map<String, String>? headers,
    String? registryId,
  }) async {
    final result = await ref
        .read(hvMcpServiceProvider)
        .addServer(url: url, name: name, headers: headers, registryId: registryId);
    final current = state.value ?? const HvMcpConsoleState();
    final persisted = [...current.persisted, result.server];
    final draft = [...current.draft, result.server];
    state = AsyncData(HvMcpConsoleState(persisted: persisted, draft: draft));
    final userId = ref.read(hvMcpUserIdProvider);
    if (userId != null) {
      await ref.read(hvMcpCacheProvider).writeServers(userId, persisted);
    }
    ref.invalidate(hvToolkitStatusProvider);
    return result;
  }

  Future<void> removeServer(String id) async {
    await ref.read(hvMcpServiceProvider).deleteServer(id);
    final current = state.value;
    if (current == null) return;
    final persisted = current.persisted.where((s) => s.id != id).toList();
    final draft = current.draft.where((s) => s.id != id).toList();
    state = AsyncData(HvMcpConsoleState(persisted: persisted, draft: draft));
    final userId = ref.read(hvMcpUserIdProvider);
    if (userId != null) {
      await ref.read(hvMcpCacheProvider).writeServers(userId, persisted);
    }
  }

  Future<void> refreshServerTools(String id) async {
    final result = await ref.read(hvMcpServiceProvider).refreshServer(id);
    final current = state.value;
    if (current == null) return;
    final knownNames = result.tools.map((t) => t.name).toSet();

    final persisted = current.persisted.map((s) {
      if (s.id != id) return s;
      return s.copyWith(
        toolsCache: result.tools,
        disabledTools: result.disabledTools,
        introspectedAt: result.introspectedAt,
      );
    }).toList();

    final draft = current.draft.map((s) {
      if (s.id != id) return s;
      return s.copyWith(
        toolsCache: result.tools,
        disabledTools: s.disabledTools.where(knownNames.contains).toList(),
        introspectedAt: result.introspectedAt,
      );
    }).toList();

    state = AsyncData(HvMcpConsoleState(persisted: persisted, draft: draft));
    final userId = ref.read(hvMcpUserIdProvider);
    if (userId != null) {
      await ref.read(hvMcpCacheProvider).writeServers(userId, persisted);
    }
  }

  Future<void> renameServer(String id, String name) async {
    final updated = await ref.read(hvMcpServiceProvider).updateServer(id, name: name);
    _mergeServer(updated);
  }

  Future<void> updateServerHeaders(
    String id, {
    Map<String, String>? headers,
    bool clear = false,
  }) async {
    final updated = await ref
        .read(hvMcpServiceProvider)
        .updateServer(id, headers: headers, clearHeaders: clear);
    _mergeServer(updated);
  }

  /// Merges a server fetched fresh from a direct PATCH (rename/re-auth) back
  /// into both lists, keeping each list's own enabled/disabledTools so an
  /// unrelated edit never clobbers pending draft toggles.
  void _mergeServer(HvMcpServer updated) {
    final current = state.value;
    if (current == null) return;
    HvMcpServer merge(HvMcpServer s) {
      if (s.id != updated.id) return s;
      return updated.copyWith(
        enabled: s.enabled,
        disabledTools: s.disabledTools,
      );
    }

    final persisted = current.persisted.map(merge).toList();
    final draft = current.draft.map(merge).toList();
    state = AsyncData(HvMcpConsoleState(persisted: persisted, draft: draft));
  }

  Future<HvCompileOutcome> compile() async {
    final current = state.value;
    if (current == null || current.draft.isEmpty) {
      throw StateError('No MCP servers to compile.');
    }
    final payload = current.draft
        .map(
          (s) => {
            'id': s.id,
            'enabled': s.enabled,
            'disabled_tools': s.disabledTools,
          },
        )
        .toList();
    final outcome = await ref.read(hvMcpServiceProvider).compileToolkit(payload);
    state = AsyncData(
      HvMcpConsoleState(persisted: current.draft, draft: current.draft),
    );
    final userId = ref.read(hvMcpUserIdProvider);
    if (userId != null) {
      await ref.read(hvMcpCacheProvider).writeServers(userId, current.draft);
    }
    ref.invalidate(hvToolkitStatusProvider);
    return outcome;
  }
}

final hvToolkitStatusProvider =
    AsyncNotifierProvider<HvToolkitStatusNotifier, HvToolkitStatus>(
      HvToolkitStatusNotifier.new,
    );

class HvToolkitStatusNotifier extends AsyncNotifier<HvToolkitStatus> {
  @override
  Future<HvToolkitStatus> build() async {
    final userId = ref.watch(hvMcpUserIdProvider);
    if (userId == null) return const HvToolkitStatus();
    return ref.read(hvMcpServiceProvider).getToolkitStatus();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(hvMcpServiceProvider).getToolkitStatus(),
    );
  }
}

class HvRegistrySearchState {
  final String query;
  final AsyncValue<HvRegistrySearchResult> result;

  const HvRegistrySearchState({
    this.query = '',
    this.result = const AsyncValue.data(HvRegistrySearchResult()),
  });
}

/// Debounced (300ms) registry search — spec T-M11-05. Riverpod 3 providers
/// dispose by default once nothing is watching, so the search sheet starts
/// clean each time it's reopened.
final hvRegistrySearchProvider =
    NotifierProvider<HvRegistrySearchNotifier, HvRegistrySearchState>(
      HvRegistrySearchNotifier.new,
    );

class HvRegistrySearchNotifier extends Notifier<HvRegistrySearchState> {
  Timer? _debounce;

  @override
  HvRegistrySearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_search);
    return const HvRegistrySearchState();
  }

  void setQuery(String query) {
    state = HvRegistrySearchState(query: query, result: state.result);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final query = state.query;
    state = HvRegistrySearchState(
      query: query,
      result: const AsyncValue.loading(),
    );
    try {
      final result = await ref.read(hvMcpServiceProvider).searchRegistry(query);
      state = HvRegistrySearchState(query: query, result: AsyncValue.data(result));
    } catch (e, st) {
      state = HvRegistrySearchState(query: query, result: AsyncValue.error(e, st));
    }
  }
}
