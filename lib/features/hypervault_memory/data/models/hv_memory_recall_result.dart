import 'hv_memory_provenance.dart';

/// One row of `GET /api/memories?q=&branch=` (recall mode) — a summary row
/// plus a relevance score, related memory titles, and a provenance receipt.
/// The top few matches also carry the exact stored [content].
class HvMemoryRecallResult {
  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final String source;
  final DateTime? createdAt;
  final double score;
  final String? content;
  final List<String> related;
  final HvMemoryProvenance? provenance;

  const HvMemoryRecallResult({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    required this.source,
    this.createdAt,
    required this.score,
    this.content,
    required this.related,
    this.provenance,
  });

  factory HvMemoryRecallResult.fromJson(Map<String, dynamic> json) {
    return HvMemoryRecallResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
      source: json['source'] as String? ?? 'manual',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      content: json['content'] as String?,
      related: ((json['related'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      provenance: HvMemoryProvenance.tryParse(json['provenance']),
    );
  }
}

/// Full response of a recall query — `recall_mode` tells the UI whether the
/// server could reach for semantic (hybrid) recall or fell back to lexical.
class HvMemoryRecallResponse {
  final String query;
  final String branch;
  final String recallMode;
  final List<HvMemoryRecallResult> results;
  final String message;

  const HvMemoryRecallResponse({
    required this.query,
    required this.branch,
    required this.recallMode,
    required this.results,
    required this.message,
  });

  bool get isHybrid => recallMode == 'hybrid';

  factory HvMemoryRecallResponse.fromJson(Map<String, dynamic> json) {
    return HvMemoryRecallResponse(
      query: json['query'] as String? ?? '',
      branch: json['branch'] as String? ?? 'main',
      recallMode: json['recall_mode'] as String? ?? 'lexical',
      results: ((json['results'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvMemoryRecallResult.fromJson(e.cast<String, dynamic>()))
          .toList(),
      message: json['message'] as String? ?? '',
    );
  }
}
