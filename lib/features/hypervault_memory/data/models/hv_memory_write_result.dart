/// Response of `POST /api/memories` ("memorize this").
class HvMemorizeResult {
  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final String branch;
  final String? commitId;
  final String message;

  const HvMemorizeResult({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    required this.branch,
    this.commitId,
    required this.message,
  });

  factory HvMemorizeResult.fromJson(Map<String, dynamic> json) {
    return HvMemorizeResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
      branch: json['branch'] as String? ?? 'main',
      commitId: json['commit_id'] as String?,
      message: json['message'] as String? ?? 'Memorized.',
    );
  }
}

/// Response of `PATCH /api/memories/[id]` (edit).
class HvMemoryEditResult {
  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final String branch;
  final String? commitId;
  final String message;

  const HvMemoryEditResult({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    required this.branch,
    this.commitId,
    required this.message,
  });

  factory HvMemoryEditResult.fromJson(Map<String, dynamic> json) {
    return HvMemoryEditResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
      branch: json['branch'] as String? ?? 'main',
      commitId: json['commit_id'] as String?,
      message: json['message'] as String? ?? 'Saved.',
    );
  }
}
