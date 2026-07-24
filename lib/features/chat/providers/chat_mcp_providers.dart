import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/providers/app_providers.dart';
import '../data/models/mcp_integration.dart';
import '../../conversations/providers/conversation_providers.dart';
import 'tooling_providers.dart';

export '../data/models/mcp_integration.dart';

class ChatMcpConfigNotifier extends Notifier<ChatMcpConfig> {
  @override
  ChatMcpConfig build() {
    // We no longer watch settingsProvider here to avoid resetting per-chat state
    // when global settings change. Initial state is set via ChatNotifier.
    Future.microtask(_loadSaved);
    return const ChatMcpConfig(enabled: true);
  }

  /// Reconnects every durably-saved on-device MCP server profile (installed
  /// from the registry, or added by hand and kept) once at app/session
  /// start — mirrors `DeepLinkNotifier`'s `Future.microtask(_bootstrap)`
  /// pattern for the same "fire an async load from a sync build()" need.
  Future<void> _loadSaved() async {
    try {
      final saved = await ref.read(mcpSavedServersStoreProvider).load();
      for (final integration in saved) {
        if (integration.serverLabel == null) continue;
        if (state.integrations.any(
          (i) => i.serverLabel == integration.serverLabel,
        )) {
          continue;
        }
        _addToState(integration);
        unawaited(_connect(integration));
      }
    } catch (e) {
      Log.warning('[mcp] failed to load saved servers: $e');
    }
  }

  void _addToState(McpIntegration integration) {
    state = state.copyWith(
      integrations: [...state.integrations, integration],
      activeMcpServers:
          integration.serverLabel != null && integration.serverUrl != null
          ? {
              ...state.activeMcpServers,
              integration.serverLabel!: integration.serverUrl!,
            }
          : state.activeMcpServers,
    );
  }

  Future<void> _connect(McpIntegration integration) {
    if (integration.serverLabel == null || integration.serverUrl == null) {
      return Future.value();
    }
    return ref
        .read(mcpServerManagerProvider)
        .addServer(
          integration.serverLabel!,
          integration.serverUrl!,
          headers: integration.headers,
        );
  }

  /// Installs [integration] as a durable, reusable on-device MCP server:
  /// connects it first (propagating any failure to the caller so an
  /// "Install" button can show a real error) and only persists +
  /// activates it once the connection succeeds. Used by the GitHub MCP
  /// registry install flow — unlike [addIntegration] (session-only, used by
  /// the chat settings sheet's quick-add form), this survives app restarts.
  Future<void> installIntegration(McpIntegration integration) async {
    await _connect(integration);
    _addToState(integration);
    final store = ref.read(mcpSavedServersStoreProvider);
    final saved = await store.load();
    final withoutDuplicate = saved
        .where((i) => i.serverLabel != integration.serverLabel)
        .toList();
    await store.save([...withoutDuplicate, integration]);
  }

  /// Reverses [installIntegration]: disconnects, drops it from live state,
  /// and removes it from durable storage so it doesn't reconnect on the
  /// next app launch.
  Future<void> uninstallIntegration(String serverLabel) async {
    final index = state.integrations.indexWhere(
      (i) => i.serverLabel == serverLabel,
    );
    if (index != -1) {
      removeIntegration(index);
    } else {
      ref.read(mcpServerManagerProvider).removeServer(serverLabel);
    }
    final store = ref.read(mcpSavedServersStoreProvider);
    final saved = await store.load();
    await store.save(
      saved.where((i) => i.serverLabel != serverLabel).toList(),
    );
  }

  bool isInstalled(String serverLabel) =>
      state.integrations.any((i) => i.serverLabel == serverLabel);

  void setConfig(ChatMcpConfig config) {
    state = config;
    final manager = ref.read(mcpServerManagerProvider);
    manager.clear();
    for (final integration in config.integrations) {
      if (integration.serverLabel != null && integration.serverUrl != null) {
        manager.addServer(
          integration.serverLabel!,
          integration.serverUrl!,
          headers: integration.headers,
        ).catchError((_) {});
      }
    }
  }

  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
  }

  void updateEnabled(WidgetRef ref, String conversationId, bool enabled) {
    state = state.copyWith(enabled: enabled);
    ref
        .read(conversationsProvider.notifier)
        .updateMcpEnabled(conversationId, enabled);
  }

  void addIntegration(McpIntegration integration) {
    state = state.copyWith(
      integrations: [...state.integrations, integration],
      activeMcpServers:
          integration.serverLabel != null && integration.serverUrl != null
          ? {
              ...state.activeMcpServers,
              integration.serverLabel!: integration.serverUrl!,
            }
          : state.activeMcpServers,
    );
    if (integration.serverLabel != null && integration.serverUrl != null) {
      ref.read(mcpServerManagerProvider).addServer(
        integration.serverLabel!,
        integration.serverUrl!,
        headers: integration.headers,
      ).catchError((_) {});
    }
  }

  void removeIntegration(int index) {
    final integration = state.integrations[index];
    final newIntegrations = List<McpIntegration>.from(state.integrations)
      ..removeAt(index);
    final newServers = Map<String, String>.from(state.activeMcpServers);
    if (integration.serverLabel != null) {
      newServers.remove(integration.serverLabel);
    }
    state = state.copyWith(
      integrations: newIntegrations,
      activeMcpServers: newServers,
    );
    if (integration.serverLabel != null) {
      ref.read(mcpServerManagerProvider).removeServer(integration.serverLabel!);
    }
  }


  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  void clearAll() {
    final settings = ref.read(settingsProvider);
    state = ChatMcpConfig(enabled: settings.newChatMcpEnabled);
    ref.read(mcpServerManagerProvider).clear();
  }
}

final chatMcpConfigProvider =
    NotifierProvider<ChatMcpConfigNotifier, ChatMcpConfig>(() {
      return ChatMcpConfigNotifier();
    });
