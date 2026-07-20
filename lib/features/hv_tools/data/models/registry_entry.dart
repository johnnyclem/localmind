/// One result from `GET /api/registry/search?q=` — untrusted external
/// content (registry name/description come from third parties), so callers
/// must render these as plain text, never as markup.
class RegistryServerEntry {
  final String? registryId;
  final String name;
  final String? url;
  final String? description;
  final String? transport;

  const RegistryServerEntry({
    this.registryId,
    required this.name,
    this.url,
    this.description,
    this.transport,
  });

  factory RegistryServerEntry.fromJson(Map<String, dynamic> json) {
    return RegistryServerEntry(
      registryId: (json['registry_id'] ?? json['id'])?.toString(),
      name: json['name']?.toString() ?? 'Untitled server',
      url: json['url']?.toString(),
      description: json['description']?.toString(),
      transport: json['transport']?.toString(),
    );
  }
}

class RegistrySearchResponse {
  final List<RegistryServerEntry> servers;
  final List<RegistryServerEntry> suggested;

  const RegistrySearchResponse({
    this.servers = const [],
    this.suggested = const [],
  });

  factory RegistrySearchResponse.fromJson(Map<String, dynamic> json) {
    List<RegistryServerEntry> parse(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RegistryServerEntry.fromJson)
          .toList();
    }

    return RegistrySearchResponse(
      servers: parse(json['servers']),
      suggested: parse(json['suggested']),
    );
  }
}
