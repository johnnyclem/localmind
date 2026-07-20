import 'hv_mcp_tool.dart';

/// `POST /api/mcp-servers/[id]/refresh` response.
class HvMcpRefreshResult {
  final List<HvMcpTool> tools;
  final List<String> disabledTools;
  final DateTime? introspectedAt;

  const HvMcpRefreshResult({
    this.tools = const [],
    this.disabledTools = const [],
    this.introspectedAt,
  });

  factory HvMcpRefreshResult.fromJson(Map<String, dynamic> json) {
    return HvMcpRefreshResult(
      tools: ((json['tools'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvMcpTool.fromJson(e.cast<String, dynamic>()))
          .toList(),
      disabledTools: ((json['disabled_tools'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      introspectedAt: DateTime.tryParse(
        json['introspected_at'] as String? ?? '',
      ),
    );
  }
}
