import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/hv_mcp_server.dart';

/// Stale-while-revalidate local cache for the last `GET /api/mcp-servers`
/// response, namespaced by HyperVault user id, so the tools console paints
/// instantly (spec docs/mobile/00-engineering-spec.md §7) instead of
/// blanking out while the network round-trip is in flight. Draft toggle
/// state is intentionally never cached — it's a per-session scratchpad that
/// resets to the persisted server list on a cold start.
class HvMcpCache {
  static const _keyPrefix = 'hv_mcp_cache_v1_';

  final SharedPreferences _prefs;

  const HvMcpCache(this._prefs);

  List<HvMcpServer>? readServers(String userId) {
    final raw = _prefs.getString('$_keyPrefix$userId');
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => HvMcpServer.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeServers(String userId, List<HvMcpServer> items) async {
    await _prefs.setString(
      '$_keyPrefix$userId',
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
