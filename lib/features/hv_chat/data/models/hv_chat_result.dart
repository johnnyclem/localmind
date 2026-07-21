import 'hv_conversation.dart';
import 'hv_message.dart';

/// `GET /api/conversations/[id]` response.
class HvConversationDetail {
  final HvConversation conversation;
  final List<HvMessage> messages;

  const HvConversationDetail({
    required this.conversation,
    required this.messages,
  });
}

/// `PATCH /api/conversations/[id]` response.
class HvVisibilityUpdateResult {
  final HvConversation conversation;
  final String? shareUrl;
  final String message;

  const HvVisibilityUpdateResult({
    required this.conversation,
    this.shareUrl,
    required this.message,
  });
}

/// `POST /api/messages/[id]/feedback` response.
class HvFeedbackResult {
  final String id;
  final String? feedback;
  final String message;

  const HvFeedbackResult({
    required this.id,
    this.feedback,
    required this.message,
  });
}

/// `GET`/`PATCH /api/chat-settings` shape — the persisted defaults for the
/// smart-context and deep-memory toggles (T-M8-08).
class HvChatSettings {
  final bool smartContext;
  final bool deepMemory;

  const HvChatSettings({this.smartContext = false, this.deepMemory = false});

  factory HvChatSettings.fromJson(Map<String, dynamic> json) {
    return HvChatSettings(
      smartContext: json['smart_context'] as bool? ?? false,
      deepMemory: json['deep_memory'] as bool? ?? false,
    );
  }

  HvChatSettings copyWith({bool? smartContext, bool? deepMemory}) {
    return HvChatSettings(
      smartContext: smartContext ?? this.smartContext,
      deepMemory: deepMemory ?? this.deepMemory,
    );
  }
}

/// `POST /api/chat` response.
class HvChatResult {
  final String conversationId;
  final HvMessage reply;
  final String? backendId;
  final String? backendName;
  final String? backendProvider;
  final List<HvRecalledItem> recalled;
  final List<String> recalledMemories;
  final bool smartContext;
  final List<String> deepMemoryLabels;
  final HvToolsSummary? tools;

  const HvChatResult({
    required this.conversationId,
    required this.reply,
    this.backendId,
    this.backendName,
    this.backendProvider,
    this.recalled = const [],
    this.recalledMemories = const [],
    this.smartContext = false,
    this.deepMemoryLabels = const [],
    this.tools,
  });

  factory HvChatResult.fromJson(Map<String, dynamic> json) {
    final replyJson = json['reply'] as Map<String, dynamic>? ?? const {};
    final backendJson = json['backend'] as Map<String, dynamic>?;

    final recalledList = ((json['recalled'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HvRecalledItem.fromJson)
        .toList();

    final recalledMemories = ((json['recalled_memories'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();

    final deepMemoryRaw = json['deep_memory'];
    final deepMemoryLabels = deepMemoryRaw is List
        ? deepMemoryRaw
              .map(
                (e) => e is Map
                    ? (e['title']?.toString() ?? e.toString())
                    : e.toString(),
              )
              .toList()
        : <String>[];

    final toolsJson = json['tools'] as Map<String, dynamic>?;
    final tools = toolsJson != null ? HvToolsSummary.fromJson(toolsJson) : null;
    final smartContext = json['smart_context'] as bool? ?? false;

    final reply = HvMessage(
      id: replyJson['id']?.toString() ?? '',
      role: replyJson['role'] as String? ?? 'assistant',
      content: replyJson['content'] as String? ?? '',
      model: replyJson['model'] as String?,
      createdAt: DateTime.now(),
      truncated: replyJson['truncated'] as bool? ?? false,
      recalledMemories: recalledMemories.isEmpty ? null : recalledMemories,
      recalled: recalledList.isEmpty ? null : recalledList,
      smartContext: smartContext,
      deepMemoryLabels: deepMemoryLabels.isEmpty ? null : deepMemoryLabels,
      tools: tools,
    );

    return HvChatResult(
      conversationId: json['conversation_id']?.toString() ?? '',
      reply: reply,
      backendId: backendJson?['id'] as String?,
      backendName: backendJson?['name'] as String?,
      backendProvider: backendJson?['provider'] as String?,
      recalled: recalledList,
      recalledMemories: recalledMemories,
      smartContext: smartContext,
      deepMemoryLabels: deepMemoryLabels,
      tools: tools,
    );
  }
}
