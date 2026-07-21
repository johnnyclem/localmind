import '../../../../core/models/canonical_message.dart';
import 'hv_message.dart';

/// `POST /api/chat/context` response — assembles the exact context (system
/// prompt + history) the server itself would use for `POST /api/chat`, so an
/// on-device model can run inference against the identical inputs instead of
/// the server (M9 on-device inference epic, api-contract.md §"POST
/// /api/chat/context").
class HvContextResult {
  final String? conversationId;
  final String system;
  final List<CanonicalMessage> messages;
  final int nextPosition;
  final List<HvRecalledItem> recalled;
  final List<String> recalledMemories;
  final bool smartContext;
  final List<String> deepMemoryLabels;

  const HvContextResult({
    this.conversationId,
    required this.system,
    required this.messages,
    required this.nextPosition,
    this.recalled = const [],
    this.recalledMemories = const [],
    this.smartContext = false,
    this.deepMemoryLabels = const [],
  });

  factory HvContextResult.fromJson(Map<String, dynamic> json) {
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

    final messages = ((json['messages'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CanonicalMessage.fromJson)
        .toList();

    return HvContextResult(
      conversationId: json['conversation_id']?.toString(),
      system: json['system'] as String? ?? '',
      messages: messages,
      nextPosition: json['next_position'] as int? ?? 0,
      recalled: recalledList,
      recalledMemories: recalledMemories,
      smartContext: json['smart_context'] as bool? ?? false,
      deepMemoryLabels: deepMemoryLabels,
    );
  }
}

/// `POST /api/chat/turns` response — persists a turn generated locally by an
/// on-device model (creates the conversation when `conversation_id` was
/// omitted).
class HvTurnResult {
  final String conversationId;
  final HvMessage reply;

  const HvTurnResult({required this.conversationId, required this.reply});

  factory HvTurnResult.fromJson(Map<String, dynamic> json) {
    final replyJson = json['reply'] as Map<String, dynamic>? ?? const {};
    return HvTurnResult(
      conversationId: json['conversation_id']?.toString() ?? '',
      reply: HvMessage(
        id: replyJson['id']?.toString() ?? '',
        role: replyJson['role'] as String? ?? 'assistant',
        content: replyJson['content'] as String? ?? '',
        model: replyJson['model'] as String?,
        createdAt: DateTime.now(),
      ),
    );
  }
}
