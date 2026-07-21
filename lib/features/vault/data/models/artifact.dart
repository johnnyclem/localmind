/// Mirrors a single item from `GET /api/artifacts` (and the `artifact`
/// object returned by `PATCH /api/artifacts`) — see
/// hypervault-web `docs/mobile/prd/03-vault-artifacts.md`.
class Artifact {
  final String slug;
  final String title;
  final String type;
  final List<String> tags;
  final String? sourcePrompt;
  final bool isPwa;
  final bool isJsx;
  final String visibility;
  final DateTime createdAt;
  final String url;

  const Artifact({
    required this.slug,
    required this.title,
    required this.type,
    required this.tags,
    this.sourcePrompt,
    required this.isPwa,
    required this.isJsx,
    required this.visibility,
    required this.createdAt,
    required this.url,
  });

  bool get isPublic => visibility == 'public';

  factory Artifact.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] as String?;
    return Artifact(
      slug: json['slug'] as String? ?? '',
      title: (rawTitle != null && rawTitle.trim().isNotEmpty)
          ? rawTitle
          : 'Untitled',
      type: json['type'] as String? ?? 'html',
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      sourcePrompt: json['source_prompt'] as String?,
      isPwa: json['is_pwa'] as bool? ?? false,
      isJsx: json['is_jsx'] as bool? ?? false,
      // A missing/absent `visibility` reads as public (pre-0016 DBs) per
      // the mobile PRD.
      visibility: json['visibility'] as String? ?? 'public',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'type': type,
    'tags': tags,
    if (sourcePrompt != null) 'source_prompt': sourcePrompt,
    'is_pwa': isPwa,
    'is_jsx': isJsx,
    'visibility': visibility,
    'created_at': createdAt.toIso8601String(),
    'url': url,
  };

  Artifact copyWith({String? visibility, String? url}) => Artifact(
    slug: slug,
    title: title,
    type: type,
    tags: tags,
    sourcePrompt: sourcePrompt,
    isPwa: isPwa,
    isJsx: isJsx,
    visibility: visibility ?? this.visibility,
    createdAt: createdAt,
    url: url ?? this.url,
  );
}

/// Response shape of `POST /api/save`. A `duplicate: true` response is still
/// a success — it just points at the pre-existing artifact instead of
/// creating a new one.
class SaveArtifactResult {
  final String url;
  final String slug;
  final bool isJsx;
  final bool isPwa;
  final String visibility;
  final int connections;
  final String message;
  final bool duplicate;

  const SaveArtifactResult({
    required this.url,
    required this.slug,
    required this.isJsx,
    required this.isPwa,
    required this.visibility,
    required this.connections,
    required this.message,
    required this.duplicate,
  });

  factory SaveArtifactResult.fromJson(Map<String, dynamic> json) {
    final rawConnections = json['connections'];
    return SaveArtifactResult(
      url: json['url'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isJsx: json['is_jsx'] as bool? ?? false,
      isPwa: json['is_pwa'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'private',
      connections: rawConnections is int
          ? rawConnections
          : int.tryParse(rawConnections?.toString() ?? '') ?? 0,
      message: json['message'] as String? ?? '',
      duplicate: json['duplicate'] as bool? ?? false,
    );
  }
}
