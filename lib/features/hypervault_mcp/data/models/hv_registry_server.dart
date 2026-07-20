/// One entry from `GET /api/registry/search` — a public MCP registry
/// server filtered to remote-capable (streamable-http/sse) transports.
class HvRegistryServer {
  final String registryId;
  final String name;
  final String description;
  final String url;
  final String transport;
  final String? version;
  final bool dead;

  const HvRegistryServer({
    required this.registryId,
    required this.name,
    required this.description,
    required this.url,
    required this.transport,
    this.version,
    this.dead = false,
  });

  factory HvRegistryServer.fromJson(Map<String, dynamic> json) {
    return HvRegistryServer(
      registryId: json['registryId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      transport: json['transport'] as String? ?? 'streamable-http',
      version: json['version'] as String?,
      dead: json['dead'] as bool? ?? false,
    );
  }
}

class HvRegistrySearchResult {
  final List<HvRegistryServer> servers;
  final List<HvRegistryServer> suggested;

  const HvRegistrySearchResult({
    this.servers = const [],
    this.suggested = const [],
  });

  factory HvRegistrySearchResult.fromJson(Map<String, dynamic> json) {
    return HvRegistrySearchResult(
      servers: ((json['servers'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvRegistryServer.fromJson(e.cast<String, dynamic>()))
          .toList(),
      suggested: ((json['suggested'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvRegistryServer.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
