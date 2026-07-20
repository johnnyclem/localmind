/// A single turn in an [HvConversation]. Mirrors the `messages[]` entries
/// from `GET /api/conversations/[id]` and the `reply` block of
/// `POST /api/chat`.
///
/// The `recalled*`/`smartContext`/`deepMemoryLabels`/`tools`/`truncated`
/// fields are only ever populated on a message that just came back from a
/// live `POST /api/chat` send — hydrated history (`GET
/// /api/conversations/[id]`) doesn't carry that per-turn provenance, so
/// those fields are simply left null for hydrated rows.
class HvMessage {
  final String id;
  final String role;
  final String content;
  final String? model;
  final int? position;
  final DateTime? createdAt;
  final String? feedback;
  final bool truncated;
  final List<String>? recalledMemories;
  final List<HvRecalledItem>? recalled;
  final bool? smartContext;
  final List<String>? deepMemoryLabels;
  final HvToolsSummary? tools;

  const HvMessage({
    required this.id,
    required this.role,
    required this.content,
    this.model,
    this.position,
    this.createdAt,
    this.feedback,
    this.truncated = false,
    this.recalledMemories,
    this.recalled,
    this.smartContext,
    this.deepMemoryLabels,
    this.tools,
  });

  bool get isUser => role == 'user';

  factory HvMessage.fromJson(Map<String, dynamic> json) {
    return HvMessage(
      id: json['id']?.toString() ?? '',
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      model: json['model'] as String?,
      position: json['position'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      feedback: normalizeFeedback(json['feedback']),
    );
  }

  /// The server stores feedback as `1`/`-1` (T-M8-03) but the mutation
  /// endpoint speaks `up`/`down`/`null` — normalize both shapes to the
  /// latter so the UI only ever deals with one vocabulary.
  static String? normalizeFeedback(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    if (s == '1' || s == 'up') return 'up';
    if (s == '-1' || s == 'down') return 'down';
    return null;
  }

  HvMessage copyWith({String? feedback, bool clearFeedback = false}) {
    return HvMessage(
      id: id,
      role: role,
      content: content,
      model: model,
      position: position,
      createdAt: createdAt,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      truncated: truncated,
      recalledMemories: recalledMemories,
      recalled: recalled,
      smartContext: smartContext,
      deepMemoryLabels: deepMemoryLabels,
      tools: tools,
    );
  }
}

/// One wiki-recall hit surfaced alongside a reply (`recalled: [{title,slug}]`
/// on `POST /api/chat`).
class HvRecalledItem {
  final String title;
  final String? slug;

  const HvRecalledItem({required this.title, this.slug});

  factory HvRecalledItem.fromJson(Map<String, dynamic> json) {
    return HvRecalledItem(
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String?,
    );
  }
}

/// Summary of a `POST /api/chat` `tools` block, reduced to what a simple
/// badge needs (v1 scope — full ToolTurn blade rendering is out of scope).
class HvToolsSummary {
  final String? status;
  final String? toolkitId;
  final int turnCount;

  const HvToolsSummary({this.status, this.toolkitId, this.turnCount = 0});

  factory HvToolsSummary.fromJson(Map<String, dynamic> json) {
    final turns = json['turns'];
    return HvToolsSummary(
      status: json['status'] as String?,
      toolkitId: json['toolkit_id'] as String?,
      turnCount: turns is List ? turns.length : 0,
    );
  }

  bool get isStale => status == 'stale';
}
