/// Data models for the Memory Wiki feature (mobile PRD M6).
///
/// Mirrors the shapes returned by hypervault-web's
/// `app/api/memories/**` routes. Kept deliberately loose where the server
/// payload itself is loosely typed (provenance, artifacts) per the epic
/// brief — "don't over-model".
library;

/// A single row from `GET /api/memories` (browse) or one entry of
/// `results[]` from `GET /api/memories?q=...` (recall/search).
class MemoryListItem {
  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final String? source;
  final DateTime createdAt;

  /// Only present on search results (`results[].score`); null for a plain
  /// browse-list row.
  final double? score;

  /// Only present on the first few search results
  /// (`RECALL_CONTENT_TOP`); null otherwise.
  final String? content;

  const MemoryListItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    this.source,
    required this.createdAt,
    this.score,
    this.content,
  });

  factory MemoryListItem.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String?;
    final rawScore = json['score'];
    return MemoryListItem(
      id: json['id']?.toString() ?? '',
      title: (rawTitle != null && rawTitle.trim().isNotEmpty)
          ? rawTitle
          : 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      source: json['source'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      score: rawScore is num ? rawScore.toDouble() : null,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'tags': tags,
    'source': source,
    'created_at': createdAt.toIso8601String(),
    if (score != null) 'score': score,
    if (content != null) 'content': content,
  };
}

/// `GET /api/memories?q=...` response envelope.
class MemorySearchResponse {
  final String query;
  final String branch;

  /// `"hybrid"` (semantic + keyword) or `"lexical"` (keyword-only fallback).
  final String recallMode;
  final List<MemoryListItem> results;
  final String message;

  const MemorySearchResponse({
    required this.query,
    required this.branch,
    required this.recallMode,
    required this.results,
    required this.message,
  });

  bool get isHybrid => recallMode == 'hybrid';

  factory MemorySearchResponse.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List?) ?? const [];
    return MemorySearchResponse(
      query: json['query'] as String? ?? '',
      branch: json['branch'] as String? ?? 'main',
      recallMode: json['recall_mode'] as String? ?? 'lexical',
      results: results
          .whereType<Map<String, dynamic>>()
          .map(MemoryListItem.fromJson)
          .toList(),
      message: json['message'] as String? ?? '',
    );
  }
}

/// A related-memory neighbor as returned by `GET /api/memories/[id]`
/// (`related[]`) — includes an `id`, unlike the title-only `related[]` seen
/// on search results, so detail-screen chips can navigate directly.
class MemoryRelatedRef {
  final String id;
  final String title;
  final String? summary;
  final List<String> tags;

  const MemoryRelatedRef({
    required this.id,
    required this.title,
    this.summary,
    this.tags = const [],
  });

  factory MemoryRelatedRef.fromJson(dynamic json) {
    if (json is String) {
      return MemoryRelatedRef(id: '', title: json);
    }
    if (json is Map<String, dynamic>) {
      final rawTitle = json['title'] as String?;
      return MemoryRelatedRef(
        id: json['id']?.toString() ?? '',
        title: (rawTitle != null && rawTitle.trim().isNotEmpty)
            ? rawTitle
            : 'Untitled',
        summary: json['summary'] as String?,
        tags: ((json['tags'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
    }
    return const MemoryRelatedRef(id: '', title: 'Untitled');
  }
}

/// An artifact bridged from a memory, as returned by
/// `GET /api/memories/[id]` (`artifacts[]`) — `{id, slug, title, type}`.
/// Loosely modeled per the epic brief: only title/slug are rendered.
class MemoryArtifactRef {
  final String? id;
  final String? slug;
  final String title;
  final String? type;

  const MemoryArtifactRef({this.id, this.slug, required this.title, this.type});

  factory MemoryArtifactRef.fromJson(dynamic json) {
    if (json is String) {
      return MemoryArtifactRef(title: json);
    }
    if (json is Map<String, dynamic>) {
      final rawTitle = json['title'] as String?;
      return MemoryArtifactRef(
        id: json['id']?.toString(),
        slug: json['slug'] as String?,
        title: (rawTitle != null && rawTitle.trim().isNotEmpty)
            ? rawTitle
            : (json['slug'] as String? ?? 'Untitled'),
        type: json['type'] as String?,
      );
    }
    return const MemoryArtifactRef(title: 'Untitled');
  }
}

/// `GET /api/memories/[id]` response — the memory itself plus its wiki
/// context (links, provenance, revision count).
class MemoryDetail {
  final String id;
  final String title;
  final String content;
  final String summary;
  final List<String> tags;
  final String? source;
  final DateTime createdAt;
  final String branch;
  final List<MemoryRelatedRef> related;
  final List<MemoryArtifactRef> artifacts;

  /// Loosely typed per the epic brief — `{commit_id, message, author_kind,
  /// author_key_prefix?, committed_at}` when present, but rendered
  /// generically as key:value pairs rather than over-modeled.
  final Map<String, dynamic> provenance;
  final int revisionCount;

  const MemoryDetail({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.tags,
    this.source,
    required this.createdAt,
    required this.branch,
    required this.related,
    required this.artifacts,
    required this.provenance,
    required this.revisionCount,
  });

  factory MemoryDetail.fromJson(Map<String, dynamic> json) {
    final memory = (json['memory'] as Map<String, dynamic>?) ?? const {};
    final rawTitle = memory['title'] as String?;
    final rawProvenance = json['provenance'];
    return MemoryDetail(
      id: memory['id']?.toString() ?? '',
      title: (rawTitle != null && rawTitle.trim().isNotEmpty)
          ? rawTitle
          : 'Untitled',
      content: memory['content'] as String? ?? '',
      summary: memory['summary'] as String? ?? '',
      tags: ((memory['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      source: memory['source'] as String?,
      createdAt:
          DateTime.tryParse(memory['created_at']?.toString() ?? '') ??
          DateTime.now(),
      branch: json['branch'] as String? ?? 'main',
      related: ((json['related'] as List?) ?? const [])
          .map(MemoryRelatedRef.fromJson)
          .toList(),
      artifacts: ((json['artifacts'] as List?) ?? const [])
          .map(MemoryArtifactRef.fromJson)
          .toList(),
      provenance: rawProvenance is Map<String, dynamic>
          ? rawProvenance
          : const {},
      revisionCount: (json['revision_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Response shape shared by `POST /api/memories`, `PATCH /api/memories/[id]`
/// and `POST /api/memories/import` — a freshly (re)committed memory summary.
class SaveMemoryResult {
  final String id;
  final String title;
  final String summary;
  final List<String> tags;
  final String? source;
  final int links;
  final String branch;
  final String? commitId;
  final String message;

  const SaveMemoryResult({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
    this.source,
    required this.links,
    required this.branch,
    this.commitId,
    required this.message,
  });

  factory SaveMemoryResult.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['links'];
    return SaveMemoryResult(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      source: json['source'] as String?,
      links: rawLinks is int
          ? rawLinks
          : int.tryParse(rawLinks?.toString() ?? '') ?? 0,
      branch: json['branch'] as String? ?? 'main',
      commitId: json['commit_id'] as String?,
      message: json['message'] as String? ?? '',
    );
  }
}
