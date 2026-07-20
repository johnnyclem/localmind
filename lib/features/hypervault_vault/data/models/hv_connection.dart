/// A raw graph edge from `GET /api/connections`. The endpoint returns three
/// separate edge tables (artifact↔artifact, memory↔memory, memory↔artifact);
/// [source] records which one this edge came from so the UI/graph can filter
/// and style them. `aId`/`bId` are internal database ids the vault-artifacts
/// list endpoint never exposes (see [HvArtifact]) — resolving them back to a
/// slug/title requires [HvVaultIdentityCache] to have seen that id before
/// (e.g. via a connect made from this app).
enum HvEdgeSource { artifactArtifact, memoryMemory, memoryArtifact }

class HvConnectionEdge {
  final String id;
  final String aId;
  final String bId;
  final String kind; // "manual" | "auto"
  final DateTime? createdAt;
  final HvEdgeSource source;

  const HvConnectionEdge({
    required this.id,
    required this.aId,
    required this.bId,
    required this.kind,
    this.createdAt,
    required this.source,
  });

  bool get isManual => kind == 'manual';

  factory HvConnectionEdge.fromJson(
    Map<String, dynamic> json,
    HvEdgeSource source,
  ) {
    final aKey = source == HvEdgeSource.memoryArtifact ? 'memory_id' : 'a_id';
    final bKey = source == HvEdgeSource.memoryArtifact
        ? 'artifact_id'
        : 'b_id';
    return HvConnectionEdge(
      id: json['id'] as String? ?? '',
      aId: json[aKey] as String? ?? '',
      bId: json[bKey] as String? ?? '',
      kind: json['kind'] as String? ?? 'auto',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      source: source,
    );
  }
}

/// Full `GET /api/connections` response.
class HvConnectionsData {
  final List<HvConnectionEdge> connections;
  final List<HvConnectionEdge> memoryLinks;
  final List<HvConnectionEdge> memoryArtifactLinks;

  const HvConnectionsData({
    this.connections = const [],
    this.memoryLinks = const [],
    this.memoryArtifactLinks = const [],
  });

  List<HvConnectionEdge> get all => [
    ...connections,
    ...memoryLinks,
    ...memoryArtifactLinks,
  ];

  factory HvConnectionsData.fromJson(Map<String, dynamic> json) {
    List<HvConnectionEdge> parse(String key, HvEdgeSource source) {
      return ((json[key] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (e) =>
                HvConnectionEdge.fromJson(e.cast<String, dynamic>(), source),
          )
          .toList();
    }

    return HvConnectionsData(
      connections: parse('connections', HvEdgeSource.artifactArtifact),
      memoryLinks: parse('memory_links', HvEdgeSource.memoryMemory),
      memoryArtifactLinks: parse(
        'memory_artifact_links',
        HvEdgeSource.memoryArtifact,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'connections': connections
        .map((e) => {'id': e.id, 'a_id': e.aId, 'b_id': e.bId, 'kind': e.kind, 'created_at': e.createdAt?.toIso8601String()})
        .toList(),
    'memory_links': memoryLinks
        .map((e) => {'id': e.id, 'a_id': e.aId, 'b_id': e.bId, 'kind': e.kind, 'created_at': e.createdAt?.toIso8601String()})
        .toList(),
    'memory_artifact_links': memoryArtifactLinks
        .map((e) => {'id': e.id, 'memory_id': e.aId, 'artifact_id': e.bId, 'kind': e.kind, 'created_at': e.createdAt?.toIso8601String()})
        .toList(),
  };
}

/// Result of `POST /api/connections`.
class HvConnectResult {
  final String fromId;
  final String toId;
  final String message;

  const HvConnectResult({
    required this.fromId,
    required this.toId,
    required this.message,
  });

  factory HvConnectResult.fromJson(Map<String, dynamic> json) {
    final ids = (json['connected'] as List?) ?? const [];
    return HvConnectResult(
      fromId: ids.isNotEmpty ? ids[0] as String? ?? '' : '',
      toId: ids.length > 1 ? ids[1] as String? ?? '' : '',
      message: json['message'] as String? ?? 'Connected.',
    );
  }
}
