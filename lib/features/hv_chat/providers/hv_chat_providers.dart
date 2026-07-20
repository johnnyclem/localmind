import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../data/hv_chat_api_service.dart';
import '../data/hv_on_device_api_service.dart';
import '../data/models/hv_chat_result.dart';
import '../data/models/hv_conversation.dart';
import '../data/models/hv_message.dart';
import '../data/on_device_chat_model.dart';

final hvChatApiServiceProvider = Provider<HvChatApiService>((ref) {
  return HvChatApiService(ref.watch(hypervaultClientProvider));
});

final hvOnDeviceApiServiceProvider = Provider<HvOnDeviceApiService>((ref) {
  return HvOnDeviceApiService(ref.watch(hypervaultClientProvider));
});

// ---------------------------------------------------------------------------
// Conversation list (T-M8-01, T-M8-16)
// ---------------------------------------------------------------------------

class HvConversationsNotifier extends AsyncNotifier<List<HvConversation>> {
  @override
  Future<List<HvConversation>> build() async {
    final api = ref.read(hvChatApiServiceProvider);
    return api.fetchConversations();
  }

  Future<void> refresh() async {
    final api = ref.read(hvChatApiServiceProvider);
    state = await AsyncValue.guard(api.fetchConversations);
  }

  /// Optimistic with rollback (mirrors `BackendsNotifier.deleteBackend`).
  Future<void> deleteConversation(String id) async {
    final current = state.value;
    if (current == null) return;
    final optimistic = current.where((c) => c.id != id).toList();
    state = AsyncData(optimistic);
    try {
      final api = ref.read(hvChatApiServiceProvider);
      await api.deleteConversation(id);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final hvConversationsProvider =
    AsyncNotifierProvider<HvConversationsNotifier, List<HvConversation>>(
      HvConversationsNotifier.new,
    );

// ---------------------------------------------------------------------------
// Persisted chat settings: smart_context / deep_memory (T-M8-08)
// ---------------------------------------------------------------------------

class HvChatSettingsNotifier extends AsyncNotifier<HvChatSettings> {
  @override
  Future<HvChatSettings> build() async {
    final api = ref.read(hvChatApiServiceProvider);
    try {
      return await api.fetchChatSettings();
    } catch (e) {
      // Failure here is harmless (spec §"Out of scope" note): fall back to
      // both off and let each send carry its own explicit toggle value.
      Log.warning('[hv-chat] chat-settings fetch failed: $e');
      return const HvChatSettings();
    }
  }

  Future<void> setSmartContext(bool value) async {
    final current = state.value ?? const HvChatSettings();
    state = AsyncData(current.copyWith(smartContext: value));
    try {
      final api = ref.read(hvChatApiServiceProvider);
      await api.updateChatSettings(smartContext: value);
    } catch (e) {
      Log.warning('[hv-chat] persist smart_context failed: $e');
    }
  }

  Future<void> setDeepMemory(bool value) async {
    final current = state.value ?? const HvChatSettings();
    state = AsyncData(current.copyWith(deepMemory: value));
    try {
      final api = ref.read(hvChatApiServiceProvider);
      await api.updateChatSettings(deepMemory: value);
    } catch (e) {
      Log.warning('[hv-chat] persist deep_memory failed: $e');
    }
  }
}

final hvChatSettingsProvider =
    AsyncNotifierProvider<HvChatSettingsNotifier, HvChatSettings>(
      HvChatSettingsNotifier.new,
    );

// ---------------------------------------------------------------------------
// A single thread (T-M8-02/03/04/10/12/15)
// ---------------------------------------------------------------------------

class HvThreadState {
  final String? conversationId;
  final String? title;
  final String? model;
  final String visibility;
  final String? shareSlug;
  final List<HvMessage> messages;
  final bool isSending;

  const HvThreadState({
    this.conversationId,
    this.title,
    this.model,
    this.visibility = 'private',
    this.shareSlug,
    this.messages = const [],
    this.isSending = false,
  });

  HvThreadState copyWith({
    String? conversationId,
    String? title,
    String? model,
    String? visibility,
    String? shareSlug,
    bool clearShareSlug = false,
    List<HvMessage>? messages,
    bool? isSending,
  }) {
    return HvThreadState(
      conversationId: conversationId ?? this.conversationId,
      title: title ?? this.title,
      model: model ?? this.model,
      visibility: visibility ?? this.visibility,
      shareSlug: clearShareSlug ? null : (shareSlug ?? this.shareSlug),
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

/// Owns one thread's history + live send state. One instance per initial
/// conversation id (`null` for a brand-new, unsaved chat) via Riverpod 3.x's
/// codegen-free family notifier convention — the arg is captured by the
/// notifier's constructor, not passed to `build()` (mirrors
/// `MemoryDetailNotifier` in `memory_providers.dart`).
///
/// Once a `null`-keyed (new chat) thread's first send resolves, this
/// notifier's *internal* [HvThreadState.conversationId] updates so further
/// sends/visibility changes target the new conversation — but the provider
/// instance itself stays keyed by `null` for the lifetime of the screen that
/// created it, which is fine: the screen never gets re-pushed with a new arg
/// mid-session.
class HvThreadNotifier extends AsyncNotifier<HvThreadState> {
  final String? initialConversationId;

  HvThreadNotifier(this.initialConversationId);

  @override
  Future<HvThreadState> build() async {
    if (initialConversationId == null) {
      return const HvThreadState();
    }
    final api = ref.read(hvChatApiServiceProvider);
    final detail = await api.fetchConversation(initialConversationId!);
    return HvThreadState(
      conversationId: detail.conversation.id,
      title: detail.conversation.title,
      model: detail.conversation.model,
      visibility: detail.conversation.visibility,
      shareSlug: detail.conversation.shareSlug,
      messages: detail.messages,
    );
  }

  /// Optimistically appends the user bubble, sends `POST /api/chat`
  /// (up to 120s), then appends the assistant reply. Rolls back the
  /// optimistic bubble and rethrows on failure so the composer can restore
  /// the draft text and surface the error (T-M8-10).
  Future<void> sendMessage({
    required String text,
    required String backendId,
    required bool useRecall,
    bool? useSmartContext,
    bool? useDeepMemory,
    bool? useTools,
  }) async {
    final current = state.value ?? const HvThreadState();
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final userMessage = HvMessage(
      id: tempId,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    final withUser = current.copyWith(
      messages: [...current.messages, userMessage],
      isSending: true,
    );
    state = AsyncData(withUser);

    final api = ref.read(hvChatApiServiceProvider);
    final wasNewConversation = current.conversationId == null;
    try {
      final result = await api.sendChat(
        backendId: backendId,
        message: text,
        conversationId: current.conversationId,
        useRecall: useRecall,
        useSmartContext: useSmartContext,
        useDeepMemory: useDeepMemory,
        useTools: useTools,
      );
      final latest = state.value ?? withUser;
      state = AsyncData(
        latest.copyWith(
          conversationId: result.conversationId,
          messages: [...latest.messages, result.reply],
          isSending: false,
        ),
      );
      if (wasNewConversation) {
        ref.invalidate(hvConversationsProvider);
      }
    } catch (e) {
      final latest = state.value ?? withUser;
      state = AsyncData(
        latest.copyWith(
          messages: latest.messages.where((m) => m.id != tempId).toList(),
          isSending: false,
        ),
      );
      rethrow;
    }
  }

  /// On-device counterpart to [sendMessage] (M9): assembles the exact same
  /// context the server would use via `POST /api/chat/context`, runs
  /// inference locally through [OnDeviceChatModel] against the currently
  /// loaded on-device model, then persists the resulting turn via `POST
  /// /api/chat/turns`. Tool use and remote recall side effects beyond
  /// context assembly are not part of this path (on-device chat is
  /// tool-free by spec). Optimistic-append/rollback mirrors [sendMessage].
  Future<void> sendMessageOnDevice({
    required String text,
    required bool useRecall,
    bool? useSmartContext,
    bool? useDeepMemory,
  }) async {
    final current = state.value ?? const HvThreadState();
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final userMessage = HvMessage(
      id: tempId,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    final withUser = current.copyWith(
      messages: [...current.messages, userMessage],
      isSending: true,
    );
    state = AsyncData(withUser);

    final wasNewConversation = current.conversationId == null;
    try {
      final engineState = ref.read(onDeviceEngineProvider);
      final loadedModelId = engineState.loadedModelId;
      if (engineState.status != OnDeviceEngineStatus.loaded ||
          loadedModelId == null) {
        throw const NoOnDeviceModelLoadedException();
      }

      final api = ref.read(hvOnDeviceApiServiceProvider);
      final context = await api.assembleContext(
        message: text,
        conversationId: current.conversationId,
        useRecall: useRecall,
        useSmartContext: useSmartContext,
        useDeepMemory: useDeepMemory,
      );

      final model = OnDeviceChatModel(
        gemmaService: ref.read(onDeviceGemmaServiceProvider),
        llamaService: ref.read(onDeviceLlamaServiceProvider),
        loadedRuntime: engineState.loadedRuntime,
        loadedModelId: loadedModelId,
      );
      final generatedText = await model.generate(
        system: context.system,
        messages: context.messages,
      );

      final turn = await api.persistTurn(
        userMessage: text,
        assistantContent: generatedText,
        conversationId: context.conversationId ?? current.conversationId,
        model: loadedModelId,
      );

      final latest = state.value ?? withUser;
      final replyMessage = HvMessage(
        id: turn.reply.id,
        role: turn.reply.role,
        content: turn.reply.content,
        model: turn.reply.model,
        createdAt: DateTime.now(),
        recalledMemories: context.recalledMemories.isEmpty
            ? null
            : context.recalledMemories,
        recalled: context.recalled.isEmpty ? null : context.recalled,
        smartContext: context.smartContext,
        deepMemoryLabels: context.deepMemoryLabels.isEmpty
            ? null
            : context.deepMemoryLabels,
      );
      state = AsyncData(
        latest.copyWith(
          conversationId: turn.conversationId,
          messages: [...latest.messages, replyMessage],
          isSending: false,
        ),
      );
      if (wasNewConversation) {
        ref.invalidate(hvConversationsProvider);
      }
    } catch (e) {
      final latest = state.value ?? withUser;
      state = AsyncData(
        latest.copyWith(
          messages: latest.messages.where((m) => m.id != tempId).toList(),
          isSending: false,
        ),
      );
      rethrow;
    }
  }

  /// `PATCH /api/conversations/[id] {visibility}` — returns the `share_url`
  /// (or `null`) for the caller to surface/copy (T-M8-15).
  Future<String?> updateVisibility(String visibility) async {
    final current = state.value;
    final id = current?.conversationId;
    if (current == null || id == null) return null;

    final api = ref.read(hvChatApiServiceProvider);
    final result = await api.updateVisibility(id, visibility);
    state = AsyncData(
      current.copyWith(
        visibility: result.conversation.visibility,
        shareSlug: result.conversation.shareSlug,
        clearShareSlug: result.conversation.shareSlug == null,
      ),
    );
    ref.invalidate(hvConversationsProvider);
    return result.shareUrl;
  }

  /// `POST /api/messages/[id]/feedback` — optimistic with rollback
  /// (T-M8-12).
  Future<void> setFeedback(String messageId, String? feedback) async {
    final current = state.value;
    if (current == null) return;
    final previous = current.messages;
    final optimistic = current.messages
        .map(
          (m) => m.id == messageId
              ? m.copyWith(feedback: feedback, clearFeedback: feedback == null)
              : m,
        )
        .toList();
    state = AsyncData(current.copyWith(messages: optimistic));
    try {
      final api = ref.read(hvChatApiServiceProvider);
      await api.setFeedback(messageId, feedback);
    } catch (e) {
      state = AsyncData(current.copyWith(messages: previous));
      rethrow;
    }
  }
}

final hvThreadProvider =
    AsyncNotifierProvider.family<HvThreadNotifier, HvThreadState, String?>(
      HvThreadNotifier.new,
    );
