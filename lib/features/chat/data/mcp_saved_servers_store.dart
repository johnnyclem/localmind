import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models/mcp_integration.dart';

/// Durable, app-lifetime list of on-device MCP server profiles the user has
/// installed (from the GitHub MCP registry or added by hand) — separate from
/// [ChatMcpConfig], which is purely in-memory Riverpod state for the current
/// app session (see `lib/features/chat/providers/chat_mcp_providers.dart`).
///
/// Backed by [FlutterSecureStorage] rather than `shared_preferences` because
/// a saved profile's `headers` map can carry a bearer/API-key secret the
/// user pasted in during install — the same sensitivity as the credentials
/// `cloud_sync` already keeps in secure storage.
class McpSavedServersStore {
  static const _key = 'mcp_saved_servers_v1';

  final FlutterSecureStorage _storage;

  const McpSavedServersStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<List<McpIntegration>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(McpIntegration.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<McpIntegration> integrations) async {
    final encoded = jsonEncode(
      integrations.map((i) => i.toJson()).toList(),
    );
    await _storage.write(key: _key, value: encoded);
  }
}
