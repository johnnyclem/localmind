import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/memory_api_service.dart';
import '../data/models/memory.dart';

final memoryApiServiceProvider = Provider<MemoryApiService>((ref) {
  return MemoryApiService(ref.watch(hypervaultClientProvider));
});

/// Owns the memory browse list (mobile PRD T-M6-01/04): stale-while-
/// revalidate cold start from [hyperVaultCacheProvider], `refresh()` for
/// pull-to-refresh, and helpers used by both the list and detail screens so
/// they stay in sync without an extra round trip. Always branch `main` —
/// branch switching is out of scope for v1 (see M7).
class MemoryListNotifier extends AsyncNotifier<List<MemoryListItem>> {
  static const _cacheKey = 'memory_list';

  @override
  Future<List<MemoryListItem>> build() async {
    final userId = ref.watch(authProvider).user?.id;
    final cache = ref.watch(hyperVaultCacheProvider);
    final cached = cache.read(_cacheKey, userId: userId);
    if (cached is List) {
      // Serve the cached list instantly, then revalidate in the background.
      unawaited(_refreshInBackground(userId));
      return cached
          .whereType<Map<String, dynamic>>()
          .map(MemoryListItem.fromJson)
          .toList();
    }
    return _fetch(userId);
  }

  /// Pull-to-refresh / explicit revalidation (also used after
  /// memorize/edit/import so the list picks up the new/changed row).
  Future<void> refresh() async {
    final userId = ref.read(authProvider).user?.id;
    state = await AsyncValue.guard(() => _fetch(userId));
  }

  Future<void> _refreshInBackground(String? userId) async {
    try {
      final fresh = await _fetch(userId);
      state = AsyncData(fresh);
    } catch (e) {
      Log.warning('[memory] list revalidate failed: $e');
    }
  }

  Future<List<MemoryListItem>> _fetch(String? userId) async {
    final api = ref.read(memoryApiServiceProvider);
    final items = await api.browse();
    await ref
        .read(hyperVaultCacheProvider)
        .put(_cacheKey, items.map((m) => m.toJson()).toList(), userId: userId);
    return items;
  }

  MemoryListItem? findById(String id) {
    final list = state.value;
    if (list == null) return null;
    for (final memory in list) {
      if (memory.id == id) return memory;
    }
    return null;
  }

  /// Optimistically drops a memory from the list (after a successful
  /// forget elsewhere), rolling back is not needed since the delete already
  /// succeeded server-side by the time this is called.
  void removeLocally(String id) {
    final previous = state.value;
    if (previous == null) return;
    state = AsyncData(previous.where((m) => m.id != id).toList());
  }
}

final memoryListProvider =
    AsyncNotifierProvider<MemoryListNotifier, List<MemoryListItem>>(
      MemoryListNotifier.new,
    );

/// Client-side substring rank over the already-loaded list (T-M6-02):
/// title/summary/tags/source, mirroring the web's `scoreRecall` closely
/// enough to feel instant before the debounced server recall lands.
List<MemoryListItem> filterMemoriesLocally(
  List<MemoryListItem> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;

  final scored = <MapEntry<MemoryListItem, int>>[];
  for (final item in items) {
    var score = 0;
    if (item.title.toLowerCase().contains(q)) score += 3;
    if (item.summary.toLowerCase().contains(q)) score += 2;
    if (item.tags.any((t) => t.toLowerCase().contains(q))) score += 2;
    if ((item.source ?? '').toLowerCase().contains(q)) score += 1;
    if (score > 0) scored.add(MapEntry(item, score));
  }
  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.map((e) => e.key).toList();
}

/// State for the debounced server recall (T-M6-03).
class MemorySearchState {
  final String query;
  final bool isSearching;
  final MemorySearchResponse? response;
  final String? error;

  const MemorySearchState({
    this.query = '',
    this.isSearching = false,
    this.response,
    this.error,
  });

  /// True once the response on hand actually answers the current query, so
  /// the screen can prefer it over the instant local filter.
  bool get hasFreshResponse =>
      response != null &&
      response!.query.trim().toLowerCase() == query.trim().toLowerCase();

  MemorySearchState copyWith({
    String? query,
    bool? isSearching,
    MemorySearchResponse? response,
    bool clearResponse = false,
    String? error,
    bool clearError = false,
  }) {
    return MemorySearchState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      response: clearResponse ? null : (response ?? this.response),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Debounces the query (~300ms, ≥2 chars per T-M6-03) and runs
/// `GET /api/memories?q=`. Stale responses (superseded by a newer query
/// before they land) are dropped via a monotonic request counter — Dio
/// cancellation isn't threaded through [HyperVaultClient], so this achieves
/// the same "abort in-flight" behavior at the UI layer.
class MemorySearchNotifier extends Notifier<MemorySearchState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  MemorySearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const MemorySearchState();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _requestId++; // invalidate any in-flight response
      state = MemorySearchState(query: query);
      return;
    }
    state = state.copyWith(query: query);
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(trimmed),
    );
  }

  Future<void> _runSearch(String query) async {
    final requestId = ++_requestId;
    state = state.copyWith(isSearching: true, clearError: true);
    try {
      final api = ref.read(memoryApiServiceProvider);
      final response = await api.search(query);
      if (requestId != _requestId) return; // superseded
      state = state.copyWith(
        isSearching: false,
        response: response,
        clearError: true,
      );
    } on HyperVaultApiException catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isSearching: false, error: e.message);
    } catch (_) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isSearching: false,
        error: 'Search failed. Check your connection.',
      );
    }
  }

  void clear() {
    _debounce?.cancel();
    _requestId++;
    state = const MemorySearchState();
  }
}

final memorySearchProvider =
    NotifierProvider<MemorySearchNotifier, MemorySearchState>(
      MemorySearchNotifier.new,
    );

/// Owns a single memory's detail (T-M6-08/09/10). One instance per memory
/// id — created via the family's `(id) => MemoryDetailNotifier(id)`
/// factory per Riverpod 3.x's codegen-free family notifier convention (the
/// arg is captured by the notifier itself, not passed to `build()`).
class MemoryDetailNotifier extends AsyncNotifier<MemoryDetail> {
  final String memoryId;

  MemoryDetailNotifier(this.memoryId);

  @override
  Future<MemoryDetail> build() async {
    final api = ref.read(memoryApiServiceProvider);
    return api.fetchDetail(memoryId);
  }

  Future<void> refresh() async {
    final api = ref.read(memoryApiServiceProvider);
    state = await AsyncValue.guard(() => api.fetchDetail(memoryId));
  }
}

final memoryDetailProvider =
    AsyncNotifierProvider.family<MemoryDetailNotifier, MemoryDetail, String>(
      MemoryDetailNotifier.new,
    );

void unawaited(Future<void> future) {
  // Intentionally fire-and-forget background revalidation.
}
