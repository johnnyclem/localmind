import 'hv_memory_provenance.dart';

/// The full page body for `GET /api/memories/[id]`.
class HvMemoryContent {
  final String id;
  final String title;
  final String content;
  final String summary;
  final List<String> tags;
  final String source;
  final DateTime? createdAt;

  const HvMemoryContent({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.tags,
    required this.source,
    this.createdAt,
  });

  factory HvMemoryContent.fromJson(Map<String, dynamic> json) {
    return HvMemoryContent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      content: json['content'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
      source: json['source'] as String? ?? 'manual',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// A linked memory neighbor — lighter than [HvMemoryContent] (no body text).
class HvMemoryLink {
  final String id;
  final String title;
  final String summary;
  final List<String> tags;

  const HvMemoryLink({
    required this.id,
    required this.title,
    required this.summary,
    required this.tags,
  });

  factory HvMemoryLink.fromJson(Map<String, dynamic> json) {
    return HvMemoryLink(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String? ?? '',
      tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(),
    );
  }
}

/// A vault artifact bridged into this memory (`memory_artifact_links`).
class HvMemoryArtifactRef {
  final String id;
  final String slug;
  final String title;
  final String type;

  const HvMemoryArtifactRef({
    required this.id,
    required this.slug,
    required this.title,
    required this.type,
  });

  factory HvMemoryArtifactRef.fromJson(Map<String, dynamic> json) {
    return HvMemoryArtifactRef(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      type: json['type'] as String? ?? '',
    );
  }
}

/// Full response of `GET /api/memories/[id]?branch=`.
class HvMemoryDetail {
  final String branch;
  final HvMemoryContent memory;
  final List<HvMemoryLink> related;
  final List<HvMemoryArtifactRef> artifacts;
  final HvMemoryProvenance? provenance;
  final int revisionCount;

  const HvMemoryDetail({
    required this.branch,
    required this.memory,
    required this.related,
    required this.artifacts,
    this.provenance,
    required this.revisionCount,
  });

  factory HvMemoryDetail.fromJson(Map<String, dynamic> json) {
    return HvMemoryDetail(
      branch: json['branch'] as String? ?? 'main',
      memory: HvMemoryContent.fromJson(
        (json['memory'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      related: ((json['related'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvMemoryLink.fromJson(e.cast<String, dynamic>()))
          .toList(),
      artifacts: ((json['artifacts'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvMemoryArtifactRef.fromJson(e.cast<String, dynamic>()))
          .toList(),
      provenance: HvMemoryProvenance.tryParse(json['provenance']),
      revisionCount: (json['revision_count'] as num?)?.toInt() ?? 0,
    );
  }
}
