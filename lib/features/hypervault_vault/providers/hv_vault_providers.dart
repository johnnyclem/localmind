import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/storage_providers.dart';
import '../../hypervault/providers/hypervault_providers.dart';
import '../data/hv_vault_cache.dart';
import '../data/hv_vault_service.dart';
import '../data/models/hv_artifact.dart';
import '../data/models/hv_connection.dart';
import '../data/models/hv_share.dart';

final hvVaultServiceProvider = Provider<HvVaultService>((ref) {
  return HvVaultService(ref.read(hyperVaultApiClientProvider));
});

final hvVaultCacheProvider = Provider<HvVaultCache>((ref) {
  return HvVaultCache(ref.read(sharedPreferencesProvider));
});

/// The signed-in HyperVault user id, or null when signed out — the cache
/// namespace key for every provider below.
final hvVaultUserIdProvider = Provider<String?>((ref) {
  return ref.watch(hyperVaultSessionProvider)?.user.id;
});

final hvArtifactsProvider =
    AsyncNotifierProvider<HvArtifactsNotifier, List<HvArtifact>>(
      HvArtifactsNotifier.new,
    );

class HvArtifactsNotifier extends AsyncNotifier<List<HvArtifact>> {
  @override
  Future<List<HvArtifact>> build() async {
    final userId = ref.watch(hvVaultUserIdProvider);
    if (userId == null) return const [];

    final cached = ref.read(hvVaultCacheProvider).readArtifacts(userId);
    if (cached != null) {
      // Serve the cached list instantly; revalidate quietly in the
      // background (pull-to-refresh surfaces errors explicitly).
      Future(() async {
        try {
          await refresh();
        } catch (_) {
          // Keep showing the cached list; the user can pull-to-refresh.
        }
      });
      return cached;
    }
    return _fetchAndCache(userId);
  }

  Future<List<HvArtifact>> _fetchAndCache(String userId) async {
    final items = await ref.read(hvVaultServiceProvider).listArtifacts();
    await ref.read(hvVaultCacheProvider).writeArtifacts(userId, items);
    return items;
  }

  /// Re-fetches from the network and updates state. Throws [HvApiError] on
  /// failure so a manual pull-to-refresh can show it — the previous state is
  /// left untouched so the list doesn't blank out on a transient error.
  Future<void> refresh() async {
    final userId = ref.read(hvVaultUserIdProvider);
    if (userId == null) return;
    final items = await _fetchAndCache(userId);
    state = AsyncData(items);
  }

  Future<void> setVisibility(String slug, String visibility) async {
    final userId = ref.read(hvVaultUserIdProvider);
    final previous = state.value ?? const <HvArtifact>[];
    final optimistic = previous
        .map((a) => a.slug == slug ? a.copyWith(visibility: visibility) : a)
        .toList();
    state = AsyncData(optimistic);
    try {
      await ref
          .read(hvVaultServiceProvider)
          .setVisibility(ref: slug, visibility: visibility);
      if (userId != null) {
        await ref.read(hvVaultCacheProvider).writeArtifacts(userId, optimistic);
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> removeArtifact(String slug) async {
    final userId = ref.read(hvVaultUserIdProvider);
    final previous = state.value ?? const <HvArtifact>[];
    final optimistic = previous.where((a) => a.slug != slug).toList();
    state = AsyncData(optimistic);
    try {
      await ref.read(hvVaultServiceProvider).deleteArtifact(slug);
      if (userId != null) {
        await ref.read(hvVaultCacheProvider).writeArtifacts(userId, optimistic);
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Prepends a freshly-saved artifact to the list (e.g. after "New from
  /// chat" succeeds) without a full round-trip.
  Future<void> prepend(HvArtifact artifact) async {
    final userId = ref.read(hvVaultUserIdProvider);
    final previous = state.value ?? const <HvArtifact>[];
    final next = [artifact, ...previous.where((a) => a.slug != artifact.slug)];
    state = AsyncData(next);
    if (userId != null) {
      await ref.read(hvVaultCacheProvider).writeArtifacts(userId, next);
    }
  }
}

final hvConnectionsProvider =
    AsyncNotifierProvider<HvConnectionsNotifier, HvConnectionsData>(
      HvConnectionsNotifier.new,
    );

class HvConnectionsNotifier extends AsyncNotifier<HvConnectionsData> {
  @override
  Future<HvConnectionsData> build() async {
    final userId = ref.watch(hvVaultUserIdProvider);
    if (userId == null) return const HvConnectionsData();

    final cached = ref.read(hvVaultCacheProvider).readConnections(userId);
    if (cached != null) {
      Future(() async {
        try {
          await refresh();
        } catch (_) {
          // Keep showing cached edges.
        }
      });
      return cached;
    }
    return _fetchAndCache(userId);
  }

  Future<HvConnectionsData> _fetchAndCache(String userId) async {
    final data = await ref.read(hvVaultServiceProvider).listConnections();
    await ref.read(hvVaultCacheProvider).writeConnections(userId, data);
    return data;
  }

  Future<void> refresh() async {
    final userId = ref.read(hvVaultUserIdProvider);
    if (userId == null) return;
    final data = await _fetchAndCache(userId);
    state = AsyncData(data);
  }

  /// Connects [sourceSlug] to [target] (an artifact slug/title or a memory
  /// id/title) and, when the target was one of the artifacts we already know
  /// the slug of, records both endpoints in the identity cache so counts and
  /// the graph can resolve this edge without another connect round-trip.
  Future<HvConnectResult> connect({
    required String sourceSlug,
    required String target,
    String? targetSlugIfArtifact,
  }) async {
    final result = await ref
        .read(hvVaultServiceProvider)
        .connect(source: sourceSlug, target: target);
    final userId = ref.read(hvVaultUserIdProvider);
    if (userId != null) {
      final cache = ref.read(hvVaultCacheProvider);
      if (result.fromId.isNotEmpty) {
        await cache.recordIdentity(userId, sourceSlug, result.fromId);
      }
      if (result.toId.isNotEmpty && targetSlugIfArtifact != null) {
        await cache.recordIdentity(userId, targetSlugIfArtifact, result.toId);
      }
    }
    try {
      await refresh();
    } catch (_) {
      // Non-fatal: the connect itself succeeded.
    }
    return result;
  }

  Future<void> disconnect(String edgeId) async {
    final previous = state.value ?? const HvConnectionsData();
    final optimistic = HvConnectionsData(
      connections: previous.connections.where((e) => e.id != edgeId).toList(),
      memoryLinks: previous.memoryLinks.where((e) => e.id != edgeId).toList(),
      memoryArtifactLinks: previous.memoryArtifactLinks
          .where((e) => e.id != edgeId)
          .toList(),
    );
    state = AsyncData(optimistic);
    final userId = ref.read(hvVaultUserIdProvider);
    try {
      await ref.read(hvVaultServiceProvider).disconnect(edgeId);
      if (userId != null) {
        await ref.read(hvVaultCacheProvider).writeConnections(userId, optimistic);
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

/// Number of resolvable edges touching [slug], or null when the artifact's
/// database id hasn't been learned yet (see [HvVaultCache]) — callers should
/// omit the badge rather than show a misleading `0`.
int? hvConnectionCountForSlug(
  HvVaultCache cache,
  HvConnectionsData data,
  String userId,
  String slug,
) {
  final id = cache.idForSlug(userId, slug);
  if (id == null) return null;
  var count = 0;
  for (final edge in data.all) {
    if (edge.aId == id || edge.bId == id) count++;
  }
  return count;
}

final hvArtifactFeedbackProvider = FutureProvider.family<String?, String>((
  ref,
  slug,
) {
  return ref.read(hvVaultServiceProvider).getFeedback(slug);
});

final hvSharesProvider = FutureProvider.family<List<HvShare>, String>((
  ref,
  artifactRef,
) {
  return ref.read(hvVaultServiceProvider).listShares(artifactRef);
});
