/// The commit a revision belongs to, as embedded in
/// `GET /api/memories/[id]/history`.
class HvMemoryCommitRef {
  final String id;
  final String message;
  final String authorKind;
  final String? authorKeyPrefix;
  final String? branch;
  final DateTime? createdAt;

  const HvMemoryCommitRef({
    required this.id,
    required this.message,
    required this.authorKind,
    this.authorKeyPrefix,
    this.branch,
    this.createdAt,
  });

  factory HvMemoryCommitRef.fromJson(Map<String, dynamic> json) {
    return HvMemoryCommitRef(
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      authorKind: json['author_kind'] as String? ?? 'user',
      authorKeyPrefix: json['author_key_prefix'] as String?,
      branch: json['branch'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  String get authorLabel {
    switch (authorKind) {
      case 'agent':
        return authorKeyPrefix != null ? 'agent $authorKeyPrefix' : 'agent';
      case 'system':
        return 'system';
      default:
        return 'you';
    }
  }
}

/// One entry of `GET /api/memories/[id]/history` — a revision plus the
/// commit that produced it (op badge: create/update/delete).
class HvMemoryRevision {
  final String revisionId;
  final String op;
  final String title;
  final String summary;
  final List<String> tags;
  final String source;
  final String? content;
  final HvMemoryCommitRef? commit;

  const HvMemoryRevision({
    required this.revisionId,
    required this.op,
    required this.title,
    required this.summary,
    required this.tags,
    required this.source,
    this.content,
    this.commit,
  });

  factory HvMemoryRevision.fromJson(Map<String, dynamic> json) {
    return HvMemoryRevision(
      revisionId: json['revision_id'] as String? ?? '',
      op: json['op'] as String? ?? 'update',
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
      source: json['source'] as String? ?? 'manual',
      content: json['content'] as String?,
      commit: json['commit'] is Map
          ? HvMemoryCommitRef.fromJson(
              (json['commit'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}
