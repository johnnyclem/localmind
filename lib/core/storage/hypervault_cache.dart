import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Per-user, stale-while-revalidate JSON read cache for HyperVault data
/// (vault list, conversations, memory browse list, branches, capabilities —
/// spec §7). Deliberately not ObjectBox: HyperVault is the source of truth
/// and this is a thin read-latency cache, not a relational local store, so a
/// flat namespaced JSON blob per key is enough and keeps every feature's
/// schema additions independent of the shared ObjectBox codegen.
class HyperVaultCache {
  static const _prefix = 'hv_cache::';
  static const _anonymousUser = 'anon';

  final SharedPreferences prefs;

  HyperVaultCache(this.prefs);

  String _key(String userId, String key) => '$_prefix$userId::$key';

  Future<void> put(String key, dynamic jsonValue, {String? userId}) {
    return prefs.setString(
      _key(userId ?? _anonymousUser, key),
      jsonEncode(jsonValue),
    );
  }

  dynamic read(String key, {String? userId}) {
    final raw = prefs.getString(_key(userId ?? _anonymousUser, key));
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearForUser(String userId) async {
    final keys = prefs.getKeys().where((k) => k.startsWith('$_prefix$userId::'));
    for (final k in keys.toList()) {
      await prefs.remove(k);
    }
  }
}
