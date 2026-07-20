/// `GET /api/toolkits` response — the compiled toolkit summary (never the
/// artifact blob itself) plus a staleness flag.
class HvToolkitStats {
  final int toolCount;
  final int uniqueSelectorCount;
  final int providerCount;
  final int collisionCount;

  const HvToolkitStats({
    this.toolCount = 0,
    this.uniqueSelectorCount = 0,
    this.providerCount = 0,
    this.collisionCount = 0,
  });

  factory HvToolkitStats.fromJson(Map<String, dynamic> json) {
    return HvToolkitStats(
      toolCount: json['toolCount'] as int? ?? 0,
      uniqueSelectorCount: json['uniqueSelectorCount'] as int? ?? 0,
      providerCount: json['providerCount'] as int? ?? 0,
      collisionCount: json['collisionCount'] as int? ?? 0,
    );
  }
}

class HvToolkit {
  final String id;
  final HvToolkitStats stats;
  final String embedderLabel;
  final DateTime? compiledAt;

  const HvToolkit({
    required this.id,
    required this.stats,
    required this.embedderLabel,
    this.compiledAt,
  });

  factory HvToolkit.fromJson(Map<String, dynamic> json) {
    return HvToolkit(
      id: json['id'] as String? ?? '',
      stats: HvToolkitStats.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      embedderLabel: json['embedder_label'] as String? ?? '',
      compiledAt: DateTime.tryParse(json['compiled_at'] as String? ?? ''),
    );
  }
}

class HvToolkitStatus {
  final HvToolkit? toolkit;
  final bool stale;

  const HvToolkitStatus({this.toolkit, this.stale = false});

  factory HvToolkitStatus.fromJson(Map<String, dynamic> json) {
    final toolkitJson = json['toolkit'];
    return HvToolkitStatus(
      toolkit: toolkitJson is Map
          ? HvToolkit.fromJson(toolkitJson.cast<String, dynamic>())
          : null,
      stale: json['stale'] as bool? ?? false,
    );
  }
}
