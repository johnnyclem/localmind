/// Data models for the Git-for-a-Mind feature (mobile PRD M7).
///
/// Mirrors the shapes returned by hypervault-web's `app/api/mind/**` and
/// `app/api/memories/[id]/history` routes. Kept loose where the server
/// payload itself is loosely typed (merge conflict snapshots, mind-state
/// memories) per the epic brief — "don't over-model".
library;

/// One row from `GET /api/mind/branches`.
class MindBranch {
  final String id;
  final String name;
  final bool isDefault;
  final String? headCommitId;
  final DateTime? createdAt;
  final int memoryCount;

  const MindBranch({
    required this.id,
    required this.name,
    required this.isDefault,
    this.headCommitId,
    this.createdAt,
    required this.memoryCount,
  });

  factory MindBranch.fromJson(Map<String, dynamic> json) => MindBranch(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    isDefault: json['is_default'] == true,
    headCommitId: json['head_commit_id']?.toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    memoryCount: (json['memory_count'] as num?)?.toInt() ?? 0,
  );
}

/// `POST /api/mind/branches` response.
class CreateBranchResult {
  final String id;
  final String name;
  final String from;
  final String? headCommitId;
  final String message;

  const CreateBranchResult({
    required this.id,
    required this.name,
    required this.from,
    this.headCommitId,
    required this.message,
  });

  factory CreateBranchResult.fromJson(Map<String, dynamic> json) =>
      CreateBranchResult(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        from: json['from'] as String? ?? 'main',
        headCommitId: json['head_commit_id']?.toString(),
        message: json['message'] as String? ?? 'Branch created.',
      );
}

/// `change_counts` embedded in a commit-log row.
class ChangeCounts {
  final int created;
  final int updated;
  final int deleted;
  final int links;

  const ChangeCounts({
    this.created = 0,
    this.updated = 0,
    this.deleted = 0,
    this.links = 0,
  });

  factory ChangeCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChangeCounts();
    return ChangeCounts(
      created: (json['created'] as num?)?.toInt() ?? 0,
      updated: (json['updated'] as num?)?.toInt() ?? 0,
      deleted: (json['deleted'] as num?)?.toInt() ?? 0,
      links: (json['links'] as num?)?.toInt() ?? 0,
    );
  }

  int get total => created + updated + deleted;
}

/// One row from `GET /api/mind/commits`.
class MindCommit {
  final String id;
  final String message;
  final String authorKind;
  final String? authorKeyPrefix;
  final String? parentCommitId;
  final String? mergeParentCommitId;
  final DateTime createdAt;
  final ChangeCounts changeCounts;

  const MindCommit({
    required this.id,
    required this.message,
    required this.authorKind,
    this.authorKeyPrefix,
    this.parentCommitId,
    this.mergeParentCommitId,
    required this.createdAt,
    required this.changeCounts,
  });

  factory MindCommit.fromJson(Map<String, dynamic> json) => MindCommit(
    id: json['id']?.toString() ?? '',
    message: json['message'] as String? ?? '(no message)',
    authorKind: json['author_kind'] as String? ?? 'user',
    authorKeyPrefix: json['author_key_prefix'] as String?,
    parentCommitId: json['parent_commit_id']?.toString(),
    mergeParentCommitId: json['merge_parent_commit_id']?.toString(),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    changeCounts: ChangeCounts.fromJson(
      json['change_counts'] as Map<String, dynamic>?,
    ),
  );

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;
  bool get isMerge => mergeParentCommitId != null;
}

/// `GET /api/mind/commits` response envelope.
class CommitLog {
  final String branch;
  final List<MindCommit> commits;

  const CommitLog({required this.branch, required this.commits});

  factory CommitLog.fromJson(Map<String, dynamic> json) => CommitLog(
    branch: json['branch'] as String? ?? 'main',
    commits: ((json['commits'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MindCommit.fromJson)
        .toList(),
  );
}

/// A memory row inside a `GET /api/mind/state` time-travel snapshot.
class MindStateMemory {
  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final String? source;
  final DateTime? committedAt;

  const MindStateMemory({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    this.source,
    this.committedAt,
  });

  factory MindStateMemory.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String?;
    return MindStateMemory(
      id: json['id']?.toString() ?? '',
      title: (rawTitle != null && rawTitle.trim().isNotEmpty)
          ? rawTitle
          : 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      source: json['source'] as String?,
      committedAt: DateTime.tryParse(json['committed_at']?.toString() ?? ''),
    );
  }
}

/// `GET /api/mind/state` response — a read-only time-travel snapshot.
class MindStateSnapshot {
  final String at;
  final String? commitId;
  final List<MindStateMemory> memories;
  final int linkCount;
  final String message;

  const MindStateSnapshot({
    required this.at,
    this.commitId,
    required this.memories,
    required this.linkCount,
    required this.message,
  });

  factory MindStateSnapshot.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['links'];
    int linkCount;
    if (rawLinks is num) {
      linkCount = rawLinks.toInt();
    } else if (rawLinks is List) {
      linkCount = rawLinks.length;
    } else {
      linkCount = int.tryParse(rawLinks?.toString() ?? '') ?? 0;
    }
    return MindStateSnapshot(
      at: json['at']?.toString() ?? '',
      commitId: json['commit_id']?.toString(),
      memories: ((json['memories'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MindStateMemory.fromJson)
          .toList(),
      linkCount: linkCount,
      message: json['message'] as String? ?? '',
    );
  }
}

/// The commit summary embedded in a `history` revision (`revision.commit`).
class RevisionCommitInfo {
  final String id;
  final String message;
  final String authorKind;
  final String? authorKeyPrefix;
  final String branch;
  final DateTime createdAt;

  const RevisionCommitInfo({
    required this.id,
    required this.message,
    required this.authorKind,
    this.authorKeyPrefix,
    required this.branch,
    required this.createdAt,
  });

  factory RevisionCommitInfo.fromJson(Map<String, dynamic> json) =>
      RevisionCommitInfo(
        id: json['id']?.toString() ?? '',
        message: json['message'] as String? ?? '',
        authorKind: json['author_kind'] as String? ?? 'user',
        authorKeyPrefix: json['author_key_prefix'] as String?,
        branch: json['branch'] as String? ?? 'main',
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// One row from `GET /api/memories/[id]/history`.
class MemoryRevision {
  final String revisionId;
  final String op; // created | updated | deleted
  final String title;
  final String summary;
  final List<String> tags;
  final String? source;
  final String? content;
  final RevisionCommitInfo? commit;

  const MemoryRevision({
    required this.revisionId,
    required this.op,
    required this.title,
    required this.summary,
    required this.tags,
    this.source,
    this.content,
    this.commit,
  });

  factory MemoryRevision.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String?;
    final rawCommit = json['commit'];
    return MemoryRevision(
      revisionId: json['revision_id']?.toString() ?? '',
      op: (json['op'] as String? ?? 'updated').toLowerCase(),
      title: (rawTitle != null && rawTitle.trim().isNotEmpty)
          ? rawTitle
          : 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      source: json['source'] as String?,
      content: json['content'] as String?,
      commit: rawCommit is Map<String, dynamic>
          ? RevisionCommitInfo.fromJson(rawCommit)
          : null,
    );
  }

  bool get isCreate => op == 'created' || op == 'create';
  bool get isUpdate => op == 'updated' || op == 'update';
  bool get isDelete => op == 'deleted' || op == 'delete';
}

/// `GET /api/memories/[id]/history` response envelope.
class MemoryHistory {
  final String memoryId;
  final List<MemoryRevision> revisions;

  const MemoryHistory({required this.memoryId, required this.revisions});

  factory MemoryHistory.fromJson(Map<String, dynamic> json) => MemoryHistory(
    memoryId: json['memory_id']?.toString() ?? '',
    revisions: ((json['revisions'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MemoryRevision.fromJson)
        .toList(),
  );
}

/// One line of a `GET /api/mind/diff` hunk list.
class DiffHunk {
  final String type; // add | del | ctx
  final String text;

  const DiffHunk({required this.type, required this.text});

  factory DiffHunk.fromJson(Map<String, dynamic> json) => DiffHunk(
    type: json['type'] as String? ?? 'ctx',
    text: json['text'] as String? ?? '',
  );
}

/// `GET /api/mind/diff` response — either a hunk list, or `{oversize:true}`
/// for a diff too large to render line-by-line.
class DiffResult {
  final List<DiffHunk> hunks;
  final bool oversize;

  const DiffResult({required this.hunks, required this.oversize});

  factory DiffResult.fromJson(Map<String, dynamic> json) {
    if (json['oversize'] == true) {
      return const DiffResult(hunks: [], oversize: true);
    }
    final rows = (json['hunks'] as List?) ?? const [];
    return DiffResult(
      hunks: rows
          .whereType<Map<String, dynamic>>()
          .map(DiffHunk.fromJson)
          .toList(),
      oversize: false,
    );
  }
}

/// `restored` block of a `POST /api/mind/revert` response.
class RevertRestored {
  final String memoryId;
  final String title;
  final String revisionId;

  const RevertRestored({
    required this.memoryId,
    required this.title,
    required this.revisionId,
  });

  factory RevertRestored.fromJson(Map<String, dynamic> json) => RevertRestored(
    memoryId: json['memory_id']?.toString() ?? '',
    title: json['title'] as String? ?? 'Untitled',
    revisionId: json['revision_id']?.toString() ?? '',
  );
}

/// `POST /api/mind/revert` response.
class RevertResult {
  final String commitId;
  final RevertRestored restored;
  final String branch;
  final String message;

  const RevertResult({
    required this.commitId,
    required this.restored,
    required this.branch,
    required this.message,
  });

  factory RevertResult.fromJson(Map<String, dynamic> json) => RevertResult(
    commitId: json['commit_id']?.toString() ?? '',
    restored: RevertRestored.fromJson(
      (json['restored'] as Map<String, dynamic>?) ?? const {},
    ),
    branch: json['branch'] as String? ?? 'main',
    message: json['message'] as String? ?? 'Restored.',
  );
}

/// `merged` counts block of a clean `POST /api/mind/merge` response.
class MergeChangeCounts {
  final int created;
  final int updated;
  final int deleted;

  const MergeChangeCounts({
    this.created = 0,
    this.updated = 0,
    this.deleted = 0,
  });

  factory MergeChangeCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MergeChangeCounts();
    return MergeChangeCounts(
      created: (json['created'] as num?)?.toInt() ?? 0,
      updated: (json['updated'] as num?)?.toInt() ?? 0,
      deleted: (json['deleted'] as num?)?.toInt() ?? 0,
    );
  }

  int get total => created + updated + deleted;
}

/// Clean (200) `POST /api/mind/merge` response.
class MergeResult {
  final String commitId;
  final MergeChangeCounts merged;
  final int linksChanged;
  final String message;

  const MergeResult({
    required this.commitId,
    required this.merged,
    required this.linksChanged,
    required this.message,
  });

  factory MergeResult.fromJson(Map<String, dynamic> json) {
    final rawLinksChanged = json['links_changed'];
    return MergeResult(
      commitId: json['commit_id']?.toString() ?? '',
      merged: MergeChangeCounts.fromJson(
        json['merged'] as Map<String, dynamic>?,
      ),
      linksChanged: rawLinksChanged is num
          ? rawLinksChanged.toInt()
          : int.tryParse(rawLinksChanged?.toString() ?? '') ?? 0,
      message: json['message'] as String? ?? 'Merged.',
    );
  }
}

/// A per-memory conflict snapshot as returned in the 409 body of
/// `POST /api/mind/merge`. `base/ours/theirs` are loosely typed per the epic
/// brief — rendered generically; `null` means "deleted on this side".
class MergeConflict {
  final String memoryId;
  final Map<String, dynamic>? base;
  final Map<String, dynamic>? ours;
  final Map<String, dynamic>? theirs;
  final List<DiffHunk> hunksOurs;
  final List<DiffHunk> hunksTheirs;

  const MergeConflict({
    required this.memoryId,
    this.base,
    this.ours,
    this.theirs,
    this.hunksOurs = const [],
    this.hunksTheirs = const [],
  });

  factory MergeConflict.fromJson(Map<String, dynamic> json) {
    List<DiffHunk> parseHunks(dynamic raw) => ((raw as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DiffHunk.fromJson)
        .toList();
    Map<String, dynamic>? asMap(dynamic raw) =>
        raw is Map<String, dynamic> ? raw : null;
    return MergeConflict(
      memoryId: json['memory_id']?.toString() ?? '',
      base: asMap(json['base']),
      ours: asMap(json['ours']),
      theirs: asMap(json['theirs']),
      hunksOurs: parseHunks(json['hunks_ours']),
      hunksTheirs: parseHunks(json['hunks_theirs']),
    );
  }

  String get title =>
      (ours?['title'] as String?) ??
      (theirs?['title'] as String?) ??
      (base?['title'] as String?) ??
      memoryId;

  String? get oursTitle => ours == null ? null : (ours!['title'] as String?);
  String? get oursContent =>
      ours == null ? null : (ours!['content'] as String?);
  String? get theirsTitle =>
      theirs == null ? null : (theirs!['title'] as String?);
  String? get theirsContent =>
      theirs == null ? null : (theirs!['content'] as String?);
}

/// Client's pick for one conflict, sent back as `resolutions[]` on the
/// resubmitted merge. v1 only offers "keep ours" / "keep theirs" — no
/// hand-edit box (see epic gaps note).
enum MergeChoice { ours, theirs }

class MergeResolution {
  final String memoryId;
  final MergeChoice choice;

  const MergeResolution({required this.memoryId, required this.choice});

  Map<String, dynamic> toJson() => {
    'memory_id': memoryId,
    'resolution': choice == MergeChoice.ours ? 'ours' : 'theirs',
  };
}
