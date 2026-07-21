import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/artifact.dart';
import '../data/vault_api_service.dart';

final vaultApiServiceProvider = Provider<VaultApiService>((ref) {
  return VaultApiService(ref.watch(hypervaultClientProvider));
});

/// Owns the vault artifact list (mobile PRD T-M3-01): stale-while-revalidate
/// cold start from [hyperVaultCacheProvider], `refresh()` for pull-to-refresh,
/// and optimistic mutators shared by the list and detail screens so both
/// stay in sync without a second round-trip.
class VaultListNotifier extends AsyncNotifier<List<Artifact>> {
  static const _cacheKey = 'vault_list';

  @override
  Future<List<Artifact>> build() async {
    final userId = ref.watch(authProvider).user?.id;
    final cache = ref.watch(hyperVaultCacheProvider);
    final cached = cache.read(_cacheKey, userId: userId);
    if (cached is List) {
      // Serve the cached list instantly, then revalidate in the background.
      unawaited(_refreshInBackground(userId));
      return cached
          .whereType<Map<String, dynamic>>()
          .map(Artifact.fromJson)
          .toList();
    }
    return _fetch(userId);
  }

  /// Pull-to-refresh / explicit revalidation.
  Future<void> refresh() async {
    final userId = ref.read(authProvider).user?.id;
    state = await AsyncValue.guard(() => _fetch(userId));
  }

  Future<void> _refreshInBackground(String? userId) async {
    try {
      final fresh = await _fetch(userId);
      state = AsyncData(fresh);
    } catch (e) {
      Log.warning('[vault] list revalidate failed: $e');
    }
  }

  Future<List<Artifact>> _fetch(String? userId) async {
    final api = ref.read(vaultApiServiceProvider);
    final items = await api.fetchArtifacts();
    await ref
        .read(hyperVaultCacheProvider)
        .put(_cacheKey, items.map((a) => a.toJson()).toList(), userId: userId);
    return items;
  }

  Artifact? findBySlug(String slug) {
    final list = state.value;
    if (list == null) return null;
    for (final artifact in list) {
      if (artifact.slug == slug) return artifact;
    }
    return null;
  }

  /// Optimistically flips visibility, persists, rolls back on failure.
  Future<void> setVisibility(String slug, String visibility) async {
    final previous = state.value ?? const <Artifact>[];
    final idx = previous.indexWhere((a) => a.slug == slug);
    if (idx != -1) {
      final optimistic = [...previous];
      optimistic[idx] = previous[idx].copyWith(visibility: visibility);
      state = AsyncData(optimistic);
    }
    try {
      await ref
          .read(vaultApiServiceProvider)
          .updateVisibility(slug: slug, visibility: visibility);
    } catch (e) {
      if (idx != -1) state = AsyncData(previous);
      rethrow;
    }
  }

  /// Optimistically removes the artifact, persists, rolls back on failure.
  Future<void> deleteArtifact(String slug) async {
    final previous = state.value ?? const <Artifact>[];
    final optimistic = previous.where((a) => a.slug != slug).toList();
    state = AsyncData(optimistic);
    try {
      await ref.read(vaultApiServiceProvider).deleteArtifact(slug: slug);
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final vaultListProvider =
    AsyncNotifierProvider<VaultListNotifier, List<Artifact>>(
      VaultListNotifier.new,
    );

void unawaited(Future<void> future) {
  // Intentionally fire-and-forget background revalidation.
}
