/// One row from `GET /api/artifacts` (see api-contract.md). Note the API
/// intentionally does not expose the artifact's internal database `id` —
/// only `slug`, which every mutation (`PATCH`/`DELETE /api/artifacts`)
/// accepts as `id|slug`. Use `slug` as the stable client-side identity.
class HvArtifact {
  final String slug;
  final String title;
  final String type;
  final List<String> tags;
  final String? sourcePrompt;
  final bool isPwa;
  final bool isJsx;
  /// Missing/absent on databases predating migration 0016 — reads as public.
  final String visibility;
  final DateTime? createdAt;
  final String url;

  const HvArtifact({
    required this.slug,
    required this.title,
    required this.type,
    this.tags = const [],
    this.sourcePrompt,
    this.isPwa = false,
    this.isJsx = false,
    this.visibility = 'public',
    this.createdAt,
    required this.url,
  });

  bool get isPrivate => visibility == 'private';

  factory HvArtifact.fromJson(Map<String, dynamic> json) {
    return HvArtifact(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      type: json['type'] as String? ?? 'html',
      tags:
          (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      sourcePrompt: json['source_prompt'] as String?,
      isPwa: json['is_pwa'] as bool? ?? false,
      isJsx: json['is_jsx'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'public',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'type': type,
    'tags': tags,
    'source_prompt': sourcePrompt,
    'is_pwa': isPwa,
    'is_jsx': isJsx,
    'visibility': visibility,
    'created_at': createdAt?.toIso8601String(),
    'url': url,
  };

  HvArtifact copyWith({String? visibility}) => HvArtifact(
    slug: slug,
    title: title,
    type: type,
    tags: tags,
    sourcePrompt: sourcePrompt,
    isPwa: isPwa,
    isJsx: isJsx,
    visibility: visibility ?? this.visibility,
    createdAt: createdAt,
    url: url,
  );
}

/// Result of `POST /api/save`.
class HvSaveResult {
  final String url;
  final String slug;
  final bool isJsx;
  final bool isPwa;
  final String visibility;
  final String message;
  final bool duplicate;

  const HvSaveResult({
    required this.url,
    required this.slug,
    required this.isJsx,
    required this.isPwa,
    required this.visibility,
    required this.message,
    this.duplicate = false,
  });

  factory HvSaveResult.fromJson(Map<String, dynamic> json) {
    return HvSaveResult(
      url: json['url'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isJsx: json['is_jsx'] as bool? ?? false,
      isPwa: json['is_pwa'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'private',
      message: json['message'] as String? ?? '',
      duplicate: json['duplicate'] as bool? ?? false,
    );
  }
}
