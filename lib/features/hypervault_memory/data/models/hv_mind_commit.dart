/// Per-commit change tally on `GET /api/mind/commits`.
class HvMindChangeCounts {
  final int created;
  final int updated;
  final int deleted;
  final int links;

  const HvMindChangeCounts({
    this.created = 0,
    this.updated = 0,
    this.deleted = 0,
    this.links = 0,
  });

  int get total => created + updated + deleted;

  factory HvMindChangeCounts.fromJson(Map<String, dynamic> json) {
    return HvMindChangeCounts(
      created: (json['created'] as num?)?.toInt() ?? 0,
      updated: (json['updated'] as num?)?.toInt() ?? 0,
      deleted: (json['deleted'] as num?)?.toInt() ?? 0,
      links: (json['links'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One row of `GET /api/mind/commits?branch=&limit=` — `git log` for a mind.
class HvMindCommit {
  final String id;
  final String message;
  final String authorKind;
  final String? authorKeyPrefix;
  final String? parentCommitId;
  final String? mergeParentCommitId;
  final DateTime? createdAt;
  final HvMindChangeCounts changeCounts;

  const HvMindCommit({
    required this.id,
    required this.message,
    required this.authorKind,
    this.authorKeyPrefix,
    this.parentCommitId,
    this.mergeParentCommitId,
    this.createdAt,
    required this.changeCounts,
  });

  /// `id.slice(0,8)` — the short hash shown in the log strip.
  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

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

  factory HvMindCommit.fromJson(Map<String, dynamic> json) {
    return HvMindCommit(
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      authorKind: json['author_kind'] as String? ?? 'user',
      authorKeyPrefix: json['author_key_prefix'] as String?,
      parentCommitId: json['parent_commit_id'] as String?,
      mergeParentCommitId: json['merge_parent_commit_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      changeCounts: HvMindChangeCounts.fromJson(
        (json['change_counts'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
