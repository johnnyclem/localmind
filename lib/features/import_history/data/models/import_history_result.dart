/// Response shape for `POST /api/import` (mobile PRD M12).
///
/// The server (`app/api/import/route.ts`) always returns `messages` as the
/// total message count across imported conversations, but this model also
/// tolerates a list-of-strings shape for `messages` in case a future server
/// build reports per-conversation notes instead — whichever shape shows up,
/// the screen renders something sensible.
class ImportHistoryResult {
  final String platform;
  final int imported;
  final int skipped;
  final int? messageCount;
  final List<String>? messages;
  final String? message;

  const ImportHistoryResult({
    required this.platform,
    required this.imported,
    required this.skipped,
    this.messageCount,
    this.messages,
    this.message,
  });

  factory ImportHistoryResult.fromJson(Map<String, dynamic> json) {
    int? messageCount;
    List<String>? messages;
    final rawMessages = json['messages'];
    if (rawMessages is num) {
      messageCount = rawMessages.toInt();
    } else if (rawMessages is List) {
      messages = rawMessages.map((e) => e.toString()).toList();
    }

    return ImportHistoryResult(
      platform: json['platform'] as String? ?? 'other',
      imported: (json['imported'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      messageCount: messageCount,
      messages: messages,
      message: json['message'] as String?,
    );
  }
}
