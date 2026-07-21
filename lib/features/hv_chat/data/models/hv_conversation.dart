/// A server-side HyperVault conversation (native or imported from
/// ChatGPT/Claude/Gemini/Grok). Mirrors `GET /api/conversations` and the
/// `conversation` block of `GET /api/conversations/[id]` — see hypervault-web
/// `docs/mobile/prd/08-chat-core.md` (T-M8-01/03).
///
/// This is intentionally separate from `lib/features/conversations`' local,
/// ObjectBox-backed `Conversation` model — that feature talks to on-device
/// models and never touches the network; this one is the parallel
/// server-chat surface (M8) and has no relationship to it.
class HvConversation {
  final String id;
  final String title;
  final String? sourcePlatform;
  final String? model;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String visibility;
  final String? shareSlug;

  const HvConversation({
    required this.id,
    required this.title,
    this.sourcePlatform,
    this.model,
    required this.createdAt,
    required this.updatedAt,
    this.visibility = 'private',
    this.shareSlug,
  });

  factory HvConversation.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String?;
    return HvConversation(
      id: json['id']?.toString() ?? '',
      title: (rawTitle != null && rawTitle.trim().isNotEmpty)
          ? rawTitle
          : 'Untitled chat',
      sourcePlatform: json['source_platform'] as String?,
      model: json['model'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      visibility: json['visibility'] as String? ?? 'private',
      shareSlug: json['share_slug'] as String?,
    );
  }

  HvConversation copyWith({
    String? title,
    String? model,
    String? visibility,
    String? shareSlug,
    bool clearShareSlug = false,
    DateTime? updatedAt,
  }) {
    return HvConversation(
      id: id,
      title: title ?? this.title,
      sourcePlatform: sourcePlatform,
      model: model ?? this.model,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visibility: visibility ?? this.visibility,
      shareSlug: clearShareSlug ? null : (shareSlug ?? this.shareSlug),
    );
  }

  /// Maps `source_platform` to the label shown on the conversation list row
  /// (T-M8-01): `chatgpt→ChatGPT, claude→Claude, gemini→Gemini, grok→Grok,
  /// hypervault/null→HyperVault, other→Imported`.
  static String platformLabel(String? source) {
    switch (source) {
      case 'chatgpt':
        return 'ChatGPT';
      case 'claude':
        return 'Claude';
      case 'gemini':
        return 'Gemini';
      case 'grok':
        return 'Grok';
      case 'hypervault':
      case null:
        return 'HyperVault';
      default:
        return 'Imported';
    }
  }
}
