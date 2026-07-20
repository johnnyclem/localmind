DateTime? parseHvDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}

/// A single tool exposed by an [McpServerEntry]. Deliberately loosely typed —
/// input schemas are not modeled client-side, only what's needed to render
/// and toggle a tool.
class McpTool {
  final String name;
  final String? description;

  const McpTool({required this.name, this.description});

  factory McpTool.fromJson(Map<String, dynamic> json) {
    return McpTool(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
  };
}

/// One connected HyperVault server-side MCP server registration, as returned
/// by `GET /api/mcp-servers` / `POST /api/mcp-servers` / the refresh
/// endpoint. This is distinct from the on-device MCP registry in
/// lib/features/mcp/ — these are servers HyperVault's backend introspects
/// and compiles into a shared toolkit for `POST /api/chat`.
class McpServerEntry {
  final String id;
  final String name;
  final String url;
  final bool hasAuth;
  final List<McpTool> tools;
  final List<String> disabledTools;
  final DateTime? introspectedAt;
  final bool enabled;

  const McpServerEntry({
    required this.id,
    required this.name,
    required this.url,
    this.hasAuth = false,
    this.tools = const [],
    this.disabledTools = const [],
    this.introspectedAt,
    this.enabled = true,
  });

  factory McpServerEntry.fromJson(Map<String, dynamic> json) {
    final rawTools = json['tools'];
    final rawDisabled = json['disabled_tools'] ?? json['disabledTools'];
    return McpServerEntry(
      id: json['id']?.toString() ?? '',
      name: (json['name']?.toString() ?? '').trim(),
      url: json['url']?.toString() ?? '',
      hasAuth: json['hasAuth'] == true || json['has_auth'] == true,
      tools: rawTools is List
          ? rawTools
                .whereType<Map<String, dynamic>>()
                .map(McpTool.fromJson)
                .toList()
          : const [],
      disabledTools: rawDisabled is List
          ? rawDisabled.map((e) => e.toString()).toList()
          : const [],
      introspectedAt: parseHvDate(
        json['introspected_at'] ?? json['introspectedAt'],
      ),
      enabled: json['enabled'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'hasAuth': hasAuth,
    'tools': tools.map((t) => t.toJson()).toList(),
    'disabled_tools': disabledTools,
    if (introspectedAt != null)
      'introspected_at': introspectedAt!.toIso8601String(),
    'enabled': enabled,
  };

  /// The `{id, enabled, disabled_tools}` shape `POST /api/toolkits/compile`
  /// expects per server in its draft payload.
  Map<String, dynamic> toCompilePayload() => {
    'id': id,
    'enabled': enabled,
    'disabled_tools': disabledTools,
  };

  int get enabledToolCount =>
      tools.where((t) => !disabledTools.contains(t.name)).length;

  McpServerEntry copyWith({
    String? id,
    String? name,
    String? url,
    bool? hasAuth,
    List<McpTool>? tools,
    List<String>? disabledTools,
    DateTime? introspectedAt,
    bool clearIntrospectedAt = false,
    bool? enabled,
  }) {
    return McpServerEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      hasAuth: hasAuth ?? this.hasAuth,
      tools: tools ?? this.tools,
      disabledTools: disabledTools ?? this.disabledTools,
      introspectedAt: clearIntrospectedAt
          ? null
          : (introspectedAt ?? this.introspectedAt),
      enabled: enabled ?? this.enabled,
    );
  }
}
