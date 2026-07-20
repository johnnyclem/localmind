import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/hv_artifact.dart';
import 'models/hv_connection.dart';

/// Stale-while-revalidate local cache for the vault feature: the last
/// `GET /api/artifacts` and `GET /api/connections` responses, plus a
/// best-effort artifact slug↔id identity map (see [HvConnectionEdge] doc —
/// the artifact list never returns `id`, so the only way to learn one is a
/// successful `POST /api/connections` made from this device). Everything is
/// namespaced by the current HyperVault user id and lives under one key
/// prefix so sign-out can drop it all via [clearCache].
class HvVaultCache {
  static const _keyPrefix = 'hv_vault_cache_v1_';

  final SharedPreferences _prefs;

  const HvVaultCache(this._prefs);

  List<HvArtifact>? readArtifacts(String userId) {
    final raw = _prefs.getString('${_keyPrefix}artifacts_$userId');
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => HvArtifact.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeArtifacts(String userId, List<HvArtifact> items) async {
    await _prefs.setString(
      '${_keyPrefix}artifacts_$userId',
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  HvConnectionsData? readConnections(String userId) {
    final raw = _prefs.getString('${_keyPrefix}connections_$userId');
    if (raw == null) return null;
    try {
      return HvConnectionsData.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeConnections(String userId, HvConnectionsData data) async {
    await _prefs.setString(
      '${_keyPrefix}connections_$userId',
      jsonEncode(data.toJson()),
    );
  }

  Map<String, String> _readIdentity(String userId) {
    final raw = _prefs.getString('${_keyPrefix}identity_$userId');
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).cast<String, String>();
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeIdentity(String userId, Map<String, String> map) async {
    await _prefs.setString('${_keyPrefix}identity_$userId', jsonEncode(map));
  }

  String? idForSlug(String userId, String slug) => _readIdentity(userId)['s:$slug'];

  String? slugForId(String userId, String id) => _readIdentity(userId)['i:$id'];

  /// Records that [slug] resolves to database [id] (both directions), e.g.
  /// after a successful connect where we already knew the artifact's slug.
  Future<void> recordIdentity(String userId, String slug, String id) async {
    final map = _readIdentity(userId);
    map['s:$slug'] = id;
    map['i:$id'] = slug;
    await _writeIdentity(userId, map);
  }

  /// Drops every cached vault entry for every user. Call on sign-out.
  static Future<void> clearCache(SharedPreferences prefs) async {
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
