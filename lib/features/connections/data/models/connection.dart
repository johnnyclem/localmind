/// Data models for `GET/POST/DELETE /api/connections` (mobile PRD M5).
///
/// The REST contract only ever hands back internal artifact/memory `id`s
/// (never slugs/titles) for each edge — see hypervault-web's
/// `app/api/connections/route.ts`. Resolving those ids into something
/// displayable (this artifact's own id, and the title/slug on the other end
/// of each edge) requires a couple of best-effort direct Supabase reads,
/// done by the connect sheet rather than modeled here.
library;

/// One row of `GET /api/connections`'s `connections` array — an
/// artifact-to-artifact edge. `a_id`/`b_id` are `artifacts.id` values, not
/// slugs.
class RawConnection {
  final String id;
  final String aId;
  final String bId;
  final String kind;
  final DateTime createdAt;

  const RawConnection({
    required this.id,
    required this.aId,
    required this.bId,
    required this.kind,
    required this.createdAt,
  });

  factory RawConnection.fromJson(Map<String, dynamic> json) {
    return RawConnection(
      id: json['id']?.toString() ?? '',
      aId: json['a_id']?.toString() ?? '',
      bId: json['b_id']?.toString() ?? '',
      kind: json['kind'] as String? ?? 'manual',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// The id on the other end of this edge, given "my" artifact id.
  String otherId(String mineId) => aId == mineId ? bId : aId;

  bool involves(String artifactId) => aId == artifactId || bId == artifactId;
}

/// `GET /api/connections` response envelope. `memory_links` and
/// `memory_artifact_links` are left unmodeled (v1 scope is artifact-to-
/// artifact connect only, per the mobile PRD note that memory targets
/// depend on M4/M6).
class ConnectionsResponse {
  final List<RawConnection> connections;

  const ConnectionsResponse({required this.connections});

  factory ConnectionsResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['connections'] as List?) ?? const [];
    return ConnectionsResponse(
      connections: items
          .whereType<Map<String, dynamic>>()
          .map(RawConnection.fromJson)
          .toList(),
    );
  }
}

/// A display-ready row for the connect sheet's "current connections" list —
/// a [RawConnection] hydrated with the other artifact's slug/title/type via
/// a direct Supabase read (see [ConnectSheet]'s `_loadExistingConnections`).
class ArtifactConnectionRow {
  final String connectionId;
  final String otherArtifactId;
  final String? otherSlug;
  final String otherTitle;
  final String? otherType;

  const ArtifactConnectionRow({
    required this.connectionId,
    required this.otherArtifactId,
    this.otherSlug,
    required this.otherTitle,
    this.otherType,
  });
}
