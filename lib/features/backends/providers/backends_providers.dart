import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/backends_api_service.dart';
import '../data/models/backend.dart';

final backendsApiServiceProvider = Provider<BackendsApiService>((ref) {
  return BackendsApiService(ref.watch(hypervaultClientProvider));
});

/// Loads + mutates the user's connected backends. Follows the same
/// stale-while-revalidate + cache pattern as `CapabilitiesNotifier`: HyperVault
/// is always the source of truth, [hyperVaultCacheProvider] just avoids a
/// blank list on cold start. Delete is optimistic with rollback (PRD
/// T-M10-07); add/update wait for the server's live connection test to
/// resolve before touching local state, since there's nothing valid to show
/// optimistically until that test passes.
class BackendsNotifier extends AsyncNotifier<BackendsListResult> {
  static const _cacheKey = 'backends';

  String? get _userId => ref.read(authProvider).user?.id;

  @override
  Future<BackendsListResult> build() async {
    final cache = ref.watch(hyperVaultCacheProvider);
    final cached = cache.read(_cacheKey, userId: _userId);
    if (cached is Map<String, dynamic>) {
      unawaited(_refresh());
      return BackendsListResult.fromJson(cached);
    }
    return _fetch();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _fetch();
      state = AsyncData(fresh);
    } catch (e) {
      Log.warning('[backends] revalidate failed: $e');
    }
  }

  Future<BackendsListResult> _fetch() async {
    final api = ref.read(backendsApiServiceProvider);
    final result = await api.fetchBackends();
    await ref.read(hyperVaultCacheProvider).put(
      _cacheKey,
      result.toJson(),
      userId: _userId,
    );
    return result;
  }

  Future<void> _persist(BackendsListResult next) async {
    state = AsyncData(next);
    await ref.read(hyperVaultCacheProvider).put(
      _cacheKey,
      next.toJson(),
      userId: _userId,
    );
  }

  Future<BackendMutationResult> addBackend({
    required String provider,
    String? name,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    String? embeddingModel,
  }) async {
    final api = ref.read(backendsApiServiceProvider);
    final result = await api.createBackend(
      provider: provider,
      name: name,
      apiKey: apiKey,
      baseUrl: baseUrl,
      defaultModel: defaultModel,
      embeddingModel: embeddingModel,
    );

    final current = state.value ?? const BackendsListResult(backends: [], providers: []);
    await _persist(
      current.copyWith(backends: [result.backend, ...current.backends]),
    );
    return result;
  }

  Future<BackendMutationResult> updateBackend({
    required String id,
    String? name,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    String? embeddingModel,
  }) async {
    final api = ref.read(backendsApiServiceProvider);
    final result = await api.updateBackend(
      id: id,
      name: name,
      apiKey: apiKey,
      baseUrl: baseUrl,
      defaultModel: defaultModel,
      embeddingModel: embeddingModel,
    );

    final current = state.value ?? const BackendsListResult(backends: [], providers: []);
    final updatedList = current.backends
        .map((b) => b.id == id ? result.backend : b)
        .toList();
    await _persist(current.copyWith(backends: updatedList));
    return result;
  }

  Future<String> deleteBackend(String id) async {
    final current = state.value;
    if (current == null) return 'Backend removed.';

    final optimistic = current.copyWith(
      backends: current.backends.where((b) => b.id != id).toList(),
    );
    state = AsyncData(optimistic);

    try {
      final api = ref.read(backendsApiServiceProvider);
      final message = await api.deleteBackend(id);
      await ref.read(hyperVaultCacheProvider).put(
        _cacheKey,
        optimistic.toJson(),
        userId: _userId,
      );
      return message;
    } catch (e) {
      // Rollback: the server never removed it, so restore the row.
      state = AsyncData(current);
      rethrow;
    }
  }
}

final backendsProvider =
    AsyncNotifierProvider<BackendsNotifier, BackendsListResult>(
      BackendsNotifier.new,
    );

void unawaited(Future<void> future) {
  // Intentionally fire-and-forget background revalidation, mirroring
  // CapabilitiesNotifier's helper of the same name in its own file.
}
