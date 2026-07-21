/// Data models for `GET/POST/DELETE /api/shares` and the direct-Supabase
/// "shared with you" read (mobile PRD M5).
library;

/// One grantee from `GET /api/shares?artifact=` (owner-only).
class ArtifactShare {
  final String id;
  final String? email;
  final String? displayName;
  final DateTime createdAt;

  const ArtifactShare({
    required this.id,
    this.email,
    this.displayName,
    required this.createdAt,
  });

  String get label {
    final name = displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    return email ?? 'Unknown';
  }

  factory ArtifactShare.fromJson(Map<String, dynamic> json) {
    return ArtifactShare(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Result of `POST /api/shares` — `{ shared_with: {email, display_name},
/// message }`.
class ShareResult {
  final String? email;
  final String? displayName;
  final String message;

  const ShareResult({this.email, this.displayName, required this.message});

  factory ShareResult.fromJson(Map<String, dynamic> json) {
    final sharedWith = json['shared_with'];
    final map = sharedWith is Map<String, dynamic> ? sharedWith : null;
    return ShareResult(
      email: map?['email'] as String?,
      displayName: map?['display_name'] as String?,
      message: json['message'] as String? ?? 'Shared.',
    );
  }
}

/// A row from the direct `artifact_shares` Supabase read for "Shared with
/// you" (T-M5-05) — no REST list endpoint exists for inbound shares, so this
/// is read straight from Postgres under RLS (`shared_with_id = auth.uid()`).
/// The exact join/table/column names are a best-effort match of
/// hypervault-web's schema (`supabase/migrations/0016_...sql` +
/// `0001_init.sql`) — parsing is defensive since the mobile PRD flags this
/// as an explicit backend gap.
class InboundShare {
  final String shareId;
  final String? artifactSlug;
  final String artifactTitle;
  final String artifactType;
  final String ownerName;
  final DateTime createdAt;

  const InboundShare({
    required this.shareId,
    this.artifactSlug,
    required this.artifactTitle,
    required this.artifactType,
    required this.ownerName,
    required this.createdAt,
  });

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  factory InboundShare.fromRow(Map<String, dynamic> row) {
    final artifact = _asMap(row['artifacts']);
    final owner = _asMap(row['owner']);

    final rawTitle = artifact?['title'] as String?;
    final ownerDisplay = owner?['display_name'] as String?;
    final ownerEmail = owner?['email'] as String?;

    return InboundShare(
      shareId: row['id']?.toString() ?? '',
      artifactSlug: artifact?['slug'] as String?,
      artifactTitle: (rawTitle != null && rawTitle.trim().isNotEmpty)
          ? rawTitle
          : 'Untitled',
      artifactType: artifact?['type'] as String? ?? 'html',
      ownerName: (ownerDisplay != null && ownerDisplay.trim().isNotEmpty)
          ? ownerDisplay
          : (ownerEmail ?? 'Someone'),
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
