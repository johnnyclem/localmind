import 'mcp_server_entry.dart';

/// `GET /api/toolkits` response — the currently compiled toolkit's metadata,
/// or null when nothing has been compiled yet.
class ToolkitStatus {
  final bool hasToolkit;
  final String? id;
  final DateTime? compiledAt;
  final int? toolCount;
  final int? uniqueSelectorCount;
  final String? embedder;
  final String? embedderLabel;
  final bool stale;

  const ToolkitStatus({
    this.hasToolkit = false,
    this.id,
    this.compiledAt,
    this.toolCount,
    this.uniqueSelectorCount,
    this.embedder,
    this.embedderLabel,
    this.stale = false,
  });

  factory ToolkitStatus.fromJson(Map<String, dynamic> json) {
    final stale = json['stale'] == true;
    final toolkit = json['toolkit'];
    if (toolkit is! Map<String, dynamic>) {
      return ToolkitStatus(hasToolkit: false, stale: stale);
    }
    final stats = toolkit['stats'];
    int? statInt(String snake, String camel) {
      if (stats is! Map) return null;
      final value = stats[snake] ?? stats[camel];
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ToolkitStatus(
      hasToolkit: true,
      id: toolkit['id']?.toString(),
      compiledAt: parseHvDate(toolkit['compiled_at'] ?? toolkit['compiledAt']),
      toolCount: statInt('tool_count', 'toolCount'),
      uniqueSelectorCount: statInt(
        'unique_selector_count',
        'uniqueSelectorCount',
      ),
      embedder: toolkit['embedder']?.toString(),
      embedderLabel:
          (toolkit['embedder_label'] ?? toolkit['embedderLabel'])?.toString(),
      stale: stale,
    );
  }

  ToolkitStatus copyWith({bool? stale}) {
    return ToolkitStatus(
      hasToolkit: hasToolkit,
      id: id,
      compiledAt: compiledAt,
      toolCount: toolCount,
      uniqueSelectorCount: uniqueSelectorCount,
      embedder: embedder,
      embedderLabel: embedderLabel,
      stale: stale ?? this.stale,
    );
  }
}

/// `POST /api/toolkits/compile` success payload. Every field is read
/// defensively (nullable) since the exact success shape isn't guaranteed.
class CompileResult {
  final int? toolCount;
  final int? uniqueSelectorCount;
  final int? collisionCount;
  final List<String> skippedServers;

  const CompileResult({
    this.toolCount,
    this.uniqueSelectorCount,
    this.collisionCount,
    this.skippedServers = const [],
  });

  factory CompileResult.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    final rawSkipped =
        json['skippedServers'] ?? json['skipped_servers'] ?? const [];
    final skipped = <String>[];
    if (rawSkipped is List) {
      for (final entry in rawSkipped) {
        if (entry is String) {
          skipped.add(entry);
        } else if (entry is Map) {
          final name = entry['name'] ?? entry['id'] ?? entry['url'];
          if (name != null) skipped.add(name.toString());
        }
      }
    }

    return CompileResult(
      toolCount: asInt(json['toolCount'] ?? json['tool_count']),
      uniqueSelectorCount: asInt(
        json['uniqueSelectorCount'] ?? json['unique_selector_count'],
      ),
      collisionCount: asInt(json['collisionCount'] ?? json['collision_count']),
      skippedServers: skipped,
    );
  }
}
