import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/providers/artifact_identity_providers.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../../core/storage/artifact_identity_cache.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/connections_api_service.dart';
import '../data/models/connection.dart';
import '../data/shares_api_service.dart';

final connectionsApiServiceProvider = Provider<ConnectionsApiService>((ref) {
  return ConnectionsApiService(ref.watch(hypervaultClientProvider));
});

final sharesApiServiceProvider = Provider<SharesApiService>((ref) {
  return SharesApiService(ref.watch(hypervaultClientProvider));
});

/// The raw `GET /api/connections` edge list, degrading to empty on failure
/// rather than surfacing an [AsyncError] — connection counts/lists are
/// supplementary to the artifact list, not blocking (mirrors
/// `vaultConnectionsProvider` in `lib/features/vault_graph/providers/
/// vault_graph_providers.dart`, which the same backing data also feeds).
final connectionsListProvider = FutureProvider<List<RawConnection>>((
  ref,
) async {
  try {
    final response = await ref
        .watch(connectionsApiServiceProvider)
        .fetchConnections();
    return response.connections;
  } catch (e) {
    Log.warning('[connections] connections fetch failed: $e');
    return const <RawConnection>[];
  }
});

/// Number of resolvable connections touching artifact [slug], or null when
/// this device hasn't learned that artifact's database id yet (see
/// [ArtifactIdentityCache]) — callers should hide the badge rather than show
/// a misleading `0` in that case.
int? connectionCountForSlug({
  required ArtifactIdentityCache cache,
  required String? userId,
  required List<RawConnection> connections,
  required String slug,
}) {
  final id = cache.idForSlug(userId, slug);
  if (id == null) return null;
  var count = 0;
  for (final connection in connections) {
    if (connection.involves(id)) count++;
  }
  return count;
}

final connectionsControllerProvider = Provider<ConnectionsController>((ref) {
  return ConnectionsController(ref);
});

/// Thin wrapper around [ConnectionsApiService.connect] used by every mobile
/// call site that creates a connection (the connect sheet today). `POST
/// /api/connections`'s response (`{connected: [fromId, toId], message}`)
/// hands back both endpoints' real database ids — since we already know
/// both endpoints' slugs at the moment we made the call, this records the
/// slug<->id identity for each in [ArtifactIdentityCache] so the vault graph
/// and connection counts/lists can resolve this edge without another
/// round-trip. See that cache's doc comment for the accepted limitation
/// (connections made purely from the web app stay unresolved until touched
/// from mobile too).
class ConnectionsController {
  final Ref _ref;

  const ConnectionsController(this._ref);

  Future<List<String>> connect({
    required String source,
    required String target,
  }) async {
    final ids = await _ref
        .read(connectionsApiServiceProvider)
        .connect(source: source, target: target);
    if (ids.length == 2) {
      final userId = _ref.read(authProvider).user?.id;
      final cache = _ref.read(artifactIdentityCacheProvider);
      await cache.recordIdentity(userId, source, ids[0]);
      await cache.recordIdentity(userId, target, ids[1]);
    }
    return ids;
  }
}
