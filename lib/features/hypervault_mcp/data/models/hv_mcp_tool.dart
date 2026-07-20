/// One tool exposed by an MCP server, as cached server-side after
/// introspection (`tools_cache` on `mcp_servers`). We only surface name and
/// description on device — dispatch (invoking the tool) is server-only.
class HvMcpTool {
  final String name;
  final String description;

  const HvMcpTool({required this.name, this.description = ''});

  factory HvMcpTool.fromJson(Map<String, dynamic> json) {
    return HvMcpTool(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'description': description};
}
