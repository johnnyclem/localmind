/// Canonical wire types shared by `POST /api/chat/context` and
/// `POST /api/chat/turns` (see api-contract.md `CanonicalMessage`).
class HvCanonicalAttachment {
  final String name;
  final String? mimeType;
  final int? size;
  final String? extractedText;

  const HvCanonicalAttachment({
    required this.name,
    this.mimeType,
    this.size,
    this.extractedText,
  });

  factory HvCanonicalAttachment.fromJson(Map<String, dynamic> json) {
    return HvCanonicalAttachment(
      name: json['name']?.toString() ?? '',
      mimeType: json['mime_type'] as String?,
      size: (json['size'] as num?)?.toInt(),
      extractedText: json['extracted_text'] as String?,
    );
  }
}

/// `role` is one of `system|user|assistant|tool` per the canonical contract.
class HvCanonicalMessage {
  final String role;
  final String content;
  final List<HvCanonicalAttachment> attachments;
  final String? model;
  final String? createdAt;

  const HvCanonicalMessage({
    required this.role,
    required this.content,
    this.attachments = const [],
    this.model,
    this.createdAt,
  });

  factory HvCanonicalMessage.fromJson(Map<String, dynamic> json) {
    return HvCanonicalMessage(
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      attachments: ((json['attachments'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvCanonicalAttachment.fromJson(e.cast<String, dynamic>()))
          .toList(),
      model: json['model'] as String?,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class HvRecalledArtifact {
  final String title;
  final String slug;

  const HvRecalledArtifact({required this.title, required this.slug});

  factory HvRecalledArtifact.fromJson(Map<String, dynamic> json) {
    return HvRecalledArtifact(
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

/// `POST /api/chat/context` response — the exact HyperVault server-chat
/// context pipeline (wiki recall, smart-context compaction, deep-memory
/// GraphRAG), assembled for a client that runs its own inference.
class HvChatContextResult {
  final String? conversationId;
  final String system;
  final List<HvCanonicalMessage> messages;
  final int nextPosition;
  final List<HvRecalledArtifact> recalled;
  final List<String> recalledMemories;
  final bool smartContext;
  final List<String>? deepMemory;

  const HvChatContextResult({
    this.conversationId,
    required this.system,
    required this.messages,
    required this.nextPosition,
    this.recalled = const [],
    this.recalledMemories = const [],
    this.smartContext = false,
    this.deepMemory,
  });

  factory HvChatContextResult.fromJson(Map<String, dynamic> json) {
    final rawDeepMemory = json['deep_memory'];
    return HvChatContextResult(
      conversationId: json['conversation_id']?.toString(),
      system: json['system']?.toString() ?? '',
      messages: ((json['messages'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvCanonicalMessage.fromJson(e.cast<String, dynamic>()))
          .toList(),
      nextPosition: (json['next_position'] as num?)?.toInt() ?? 0,
      recalled: ((json['recalled'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvRecalledArtifact.fromJson(e.cast<String, dynamic>()))
          .toList(),
      recalledMemories: ((json['recalled_memories'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      smartContext: json['smart_context'] == true,
      deepMemory: rawDeepMemory is List
          ? rawDeepMemory.map((e) => e.toString()).toList()
          : null,
    );
  }
}

/// `POST /api/chat/turns` response.
class HvTurnResult {
  final String conversationId;
  final String replyId;
  final String content;
  final String model;

  const HvTurnResult({
    required this.conversationId,
    required this.replyId,
    required this.content,
    required this.model,
  });

  factory HvTurnResult.fromJson(Map<String, dynamic> json) {
    final reply = (json['reply'] as Map?)?.cast<String, dynamic>() ?? const {};
    return HvTurnResult(
      conversationId: json['conversation_id']?.toString() ?? '',
      replyId: reply['id']?.toString() ?? '',
      content: reply['content']?.toString() ?? '',
      model: reply['model']?.toString() ?? '',
    );
  }
}
