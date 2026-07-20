/// One row of `GET /api/memories?branch=` (browse mode) — a wiki index
/// entry without full content.
class HvMemorySummary {
  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final String source;
  final DateTime? createdAt;

  const HvMemorySummary({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    required this.source,
    this.createdAt,
  });

  factory HvMemorySummary.fromJson(Map<String, dynamic> json) {
    return HvMemorySummary(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
      source: json['source'] as String? ?? 'manual',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
