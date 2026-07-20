import 'hv_mcp_tool.dart';

/// A connected MCP server as returned by `publicServer()` on the HyperVault
/// backend — auth header ciphers are stripped server-side and replaced with
/// [hasAuth]/[secretBacked]/[authType]; a secret value is never sent to a
/// client. See docs/mobile/prd/api-contract.md `GET /api/mcp-servers`.
class HvMcpServer {
  final String id;
  final String name;
  final String url;
  final bool enabled;
  final List<String> disabledTools;
  final List<HvMcpTool> toolsCache;
  final DateTime? introspectedAt;
  final String? registryId;
  final bool hasAuth;
  final bool secretBacked;
  final String? authType;
  final DateTime? createdAt;

  const HvMcpServer({
    required this.id,
    required this.name,
    required this.url,
    this.enabled = true,
    this.disabledTools = const [],
    this.toolsCache = const [],
    this.introspectedAt,
    this.registryId,
    this.hasAuth = false,
    this.secretBacked = false,
    this.authType,
    this.createdAt,
  });

  int get enabledToolCount => toolsCache.length - disabledTools.length;

  factory HvMcpServer.fromJson(Map<String, dynamic> json) {
    return HvMcpServer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      disabledTools:
          ((json['disabled_tools'] as List?) ?? const [])
              .whereType<String>()
              .toList(),
      toolsCache:
          ((json['tools_cache'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => HvMcpTool.fromJson(e.cast<String, dynamic>()))
              .toList(),
      introspectedAt: DateTime.tryParse(
        json['introspected_at'] as String? ?? '',
      ),
      registryId: json['registry_id'] as String?,
      hasAuth: json['has_auth'] as bool? ?? false,
      secretBacked: json['secret_backed'] as bool? ?? false,
      authType: json['auth_type'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'enabled': enabled,
    'disabled_tools': disabledTools,
    'tools_cache': toolsCache.map((t) => t.toJson()).toList(),
    'introspected_at': introspectedAt?.toIso8601String(),
    'registry_id': registryId,
    'has_auth': hasAuth,
    'secret_backed': secretBacked,
    'auth_type': authType,
    'created_at': createdAt?.toIso8601String(),
  };

  HvMcpServer copyWith({
    String? name,
    bool? enabled,
    List<String>? disabledTools,
    List<HvMcpTool>? toolsCache,
    DateTime? introspectedAt,
  }) {
    return HvMcpServer(
      id: id,
      name: name ?? this.name,
      url: url,
      enabled: enabled ?? this.enabled,
      disabledTools: disabledTools ?? this.disabledTools,
      toolsCache: toolsCache ?? this.toolsCache,
      introspectedAt: introspectedAt ?? this.introspectedAt,
      registryId: registryId,
      hasAuth: hasAuth,
      secretBacked: secretBacked,
      authType: authType,
      createdAt: createdAt,
    );
  }
}
