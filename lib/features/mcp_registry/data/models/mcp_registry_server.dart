/// Dart models for the official MCP Registry's `server.json` format
/// (https://registry.modelcontextprotocol.io — the API backing GitHub's MCP
/// Registry at github.com/mcp). Distinct from
/// lib/features/hv_tools/data/models/registry_entry.dart, which models
/// HyperVault's own lossy `/api/registry/search` proxy response; these types
/// mirror the upstream schema closely enough to drive install-compatibility
/// decisions (stdio vs. remote, declared auth headers, OAuth likelihood).
library;

/// One variable declaration shared by `packages[].environmentVariables[]`
/// and `remotes[].headers[]` — same shape in both places per the schema.
class McpRegistryVariable {
  final String name;
  final String? description;
  final bool isRequired;
  final bool isSecret;
  final String? format;
  final String? defaultValue;
  final List<String> choices;

  const McpRegistryVariable({
    required this.name,
    this.description,
    this.isRequired = false,
    this.isSecret = false,
    this.format,
    this.defaultValue,
    this.choices = const [],
  });

  factory McpRegistryVariable.fromJson(Map<String, dynamic> json) {
    return McpRegistryVariable(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isRequired: json['isRequired'] == true || json['is_required'] == true,
      isSecret: json['isSecret'] == true || json['is_secret'] == true,
      format: json['format']?.toString(),
      defaultValue: json['default']?.toString(),
      choices: (json['choices'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class McpRegistryTransport {
  final String type; // 'stdio' | 'sse' | 'streamable-http'
  final String? url;

  const McpRegistryTransport({required this.type, this.url});

  factory McpRegistryTransport.fromJson(Map<String, dynamic> json) {
    return McpRegistryTransport(
      type: json['type']?.toString() ?? 'stdio',
      url: json['url']?.toString(),
    );
  }
}

/// A locally-run distribution of the server (npm/pypi/oci/... package
/// invoked via stdio). Mobile (iOS/Android, no desktop target in this repo)
/// cannot spawn arbitrary local processes, so entries whose server only has
/// `packages` and no `remotes` are shown but not installable — see
/// `McpRegistryInstallTarget.unsupportedStdio`.
class McpRegistryPackage {
  final String registryType; // npm | pypi | cargo | nuget | oci | mcpb
  final String? registryBaseUrl;
  final String identifier;
  final String? version;
  final String? runtimeHint;
  final McpRegistryTransport transport;
  final List<McpRegistryVariable> environmentVariables;

  const McpRegistryPackage({
    required this.registryType,
    this.registryBaseUrl,
    required this.identifier,
    this.version,
    this.runtimeHint,
    required this.transport,
    this.environmentVariables = const [],
  });

  factory McpRegistryPackage.fromJson(Map<String, dynamic> json) {
    final transportJson = json['transport'];
    return McpRegistryPackage(
      registryType: json['registryType']?.toString() ?? 'npm',
      registryBaseUrl: json['registryBaseUrl']?.toString(),
      identifier: json['identifier']?.toString() ?? '',
      version: json['version']?.toString(),
      runtimeHint: json['runtimeHint']?.toString(),
      transport: transportJson is Map<String, dynamic>
          ? McpRegistryTransport.fromJson(transportJson)
          : const McpRegistryTransport(type: 'stdio'),
      environmentVariables: (json['environmentVariables'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(McpRegistryVariable.fromJson)
              .toList() ??
          const [],
    );
  }
}

/// A hosted endpoint for the server (what the on-device or HyperVault MCP
/// clients actually connect to over HTTP).
class McpRegistryRemote {
  final String type; // 'sse' | 'streamable-http'
  final String url;
  final List<McpRegistryVariable> headers;

  const McpRegistryRemote({
    required this.type,
    required this.url,
    this.headers = const [],
  });

  factory McpRegistryRemote.fromJson(Map<String, dynamic> json) {
    return McpRegistryRemote(
      type: json['type']?.toString() ?? 'streamable-http',
      url: json['url']?.toString() ?? '',
      headers: (json['headers'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(McpRegistryVariable.fromJson)
              .toList() ??
          const [],
    );
  }

  /// Headers the registry says the client must attach on every request.
  /// A remote with none of these declared — but that still requires auth —
  /// is the signal we use to suspect the server needs an interactive OAuth
  /// flow instead of a static header (see McpRegistryInstallTarget).
  bool get hasDeclaredSecretHeaders => headers.any((h) => h.isSecret);
}

class McpRegistryRepository {
  final String url;
  final String? source;

  const McpRegistryRepository({required this.url, this.source});

  factory McpRegistryRepository.fromJson(Map<String, dynamic> json) {
    return McpRegistryRepository(
      url: json['url']?.toString() ?? '',
      source: json['source']?.toString(),
    );
  }
}

/// One server.json entry as returned by `GET /v0.1/servers` or
/// `GET /v0.1/servers/{name}/versions/{version}`.
class McpRegistryServer {
  final String name;
  final String? title;
  final String description;
  final String version;
  final String? websiteUrl;
  final McpRegistryRepository? repository;
  final List<McpRegistryPackage> packages;
  final List<McpRegistryRemote> remotes;
  final String? status;
  final DateTime? publishedAt;

  const McpRegistryServer({
    required this.name,
    this.title,
    this.description = '',
    this.version = '',
    this.websiteUrl,
    this.repository,
    this.packages = const [],
    this.remotes = const [],
    this.status,
    this.publishedAt,
  });

  String get displayName {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    final short = name.contains('/') ? name.split('/').last : name;
    return short.isEmpty ? name : short;
  }

  bool get hasRemote => remotes.isNotEmpty;
  bool get hasStdioOnly => remotes.isEmpty && packages.isNotEmpty;
  bool get isInstallable => hasRemote;

  /// Preferred remote when a server declares more than one — favors
  /// `streamable-http` (the current spec's primary transport) over `sse`.
  McpRegistryRemote? get primaryRemote {
    if (remotes.isEmpty) return null;
    for (final r in remotes) {
      if (r.type == 'streamable-http') return r;
    }
    return remotes.first;
  }

  /// Parses one entry from the `servers` array of a list response, or a
  /// single-version response. Both wrap the actual server.json fields under
  /// a `server` key alongside a registry-owned `_meta` block; this also
  /// accepts an unwrapped server object defensively.
  factory McpRegistryServer.fromJson(Map<String, dynamic> json) {
    final serverJson = json['server'] is Map<String, dynamic>
        ? json['server'] as Map<String, dynamic>
        : json;

    final repoJson = serverJson['repository'];
    final meta = json['_meta'];
    String? status;
    DateTime? publishedAt;
    if (meta is Map<String, dynamic>) {
      final official = meta['io.modelcontextprotocol.registry/official'];
      if (official is Map<String, dynamic>) {
        status = official['status']?.toString();
        final published = official['publishedAt'];
        if (published is String) publishedAt = DateTime.tryParse(published);
      }
    }

    return McpRegistryServer(
      name: serverJson['name']?.toString() ?? '',
      title: serverJson['title']?.toString(),
      description: serverJson['description']?.toString() ?? '',
      version: serverJson['version']?.toString() ?? '',
      websiteUrl: serverJson['websiteUrl']?.toString(),
      repository: repoJson is Map<String, dynamic>
          ? McpRegistryRepository.fromJson(repoJson)
          : null,
      packages: (serverJson['packages'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(McpRegistryPackage.fromJson)
              .toList() ??
          const [],
      remotes: (serverJson['remotes'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(McpRegistryRemote.fromJson)
              .toList() ??
          const [],
      status: status,
      publishedAt: publishedAt,
    );
  }
}

/// One page of `GET /v0.1/servers`.
class McpRegistryPage {
  final List<McpRegistryServer> servers;
  final String? nextCursor;

  const McpRegistryPage({this.servers = const [], this.nextCursor});

  factory McpRegistryPage.fromJson(Map<String, dynamic> json) {
    final list = json['servers'];
    final metadata = json['metadata'];
    return McpRegistryPage(
      servers: list is List
          ? list
              .whereType<Map<String, dynamic>>()
              .map(McpRegistryServer.fromJson)
              .toList()
          : const [],
      nextCursor: metadata is Map<String, dynamic>
          ? metadata['nextCursor']?.toString()
          : null,
    );
  }
}
