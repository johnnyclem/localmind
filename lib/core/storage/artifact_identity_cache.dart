import 'hypervault_cache.dart';

/// Slug<->id identity cache for vault artifacts.
///
/// The bug this fixes: `GET /api/artifacts` (`lib/features/vault/data/
/// vault_api_service.dart`) never returns an artifact's internal database
/// `id`, only its `slug` — while `GET`/`POST /api/connections`
/// (`lib/features/vault_graph/`, `lib/features/connections/`) is keyed by
/// the artifacts' database `a_id`/`b_id`. Without a way to map one to the
/// other, no connection edge can ever be resolved against the artifact
/// list, so the vault graph renders nodes with no edges and the connect
/// sheet's "current connections" list has nothing to match against.
///
/// The fix: `POST /api/connections`'s response (`{connected: [fromId,
/// toId], message}`) hands back the real database ids for both endpoints
/// of a connection we just made — and at that moment we already know both
/// endpoints' slugs (the source we connected from, and the target we
/// searched for and picked by slug). [recordIdentity] captures that
/// slug<->id pairing so it can be looked up later from either direction.
///
/// This is intentionally a best-effort, not a complete, fix: a connection
/// made purely from the web app — never touched from this device — has no
/// mobile-side moment where both a slug and an id are known together, so it
/// stays unresolved until someone connects through mobile too. That is an
/// accepted, documented limitation (matches the discarded reference
/// implementation's own approach in `hv_vault_cache.dart`).
///
/// Storage is a flat per-user JSON map on top of the existing
/// [HyperVaultCache] KV pattern (see `lib/features/vault/providers/
/// vault_providers.dart` for another consumer of that same cache) rather
/// than a new persistence mechanism.
class ArtifactIdentityCache {
  static const _key = 'artifact_identity_v1';

  final HyperVaultCache _cache;

  ArtifactIdentityCache(this._cache);

  Map<String, String> _readMap(String? userId) {
    final raw = _cache.read(_key, userId: userId);
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    return {};
  }

  Future<void> _writeMap(String? userId, Map<String, String> map) {
    return _cache.put(_key, map, userId: userId);
  }

  /// The database id [slug] resolves to, or null if this device hasn't
  /// learned it yet.
  String? idForSlug(String? userId, String slug) {
    if (slug.isEmpty) return null;
    return _readMap(userId)['s:$slug'];
  }

  /// The slug that database [id] resolves to, or null if this device
  /// hasn't learned it yet.
  String? slugForId(String? userId, String id) {
    if (id.isEmpty) return null;
    return _readMap(userId)['i:$id'];
  }

  /// Records that [slug] and [id] refer to the same artifact, both
  /// directions. Safe to call repeatedly — last write wins and repeated
  /// calls with the same pair are harmless.
  Future<void> recordIdentity(String? userId, String slug, String id) async {
    if (slug.isEmpty || id.isEmpty) return;
    final map = _readMap(userId);
    if (map['s:$slug'] == id && map['i:$id'] == slug) return;
    map['s:$slug'] = id;
    map['i:$id'] = slug;
    await _writeMap(userId, map);
  }
}
