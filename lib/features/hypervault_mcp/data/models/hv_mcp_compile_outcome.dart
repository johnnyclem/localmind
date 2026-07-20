import 'hv_mcp_toolkit_status.dart';

class HvCompileCollision {
  final String selectorA;
  final String selectorB;
  final double similarity;
  final String hint;

  const HvCompileCollision({
    required this.selectorA,
    required this.selectorB,
    required this.similarity,
    required this.hint,
  });

  factory HvCompileCollision.fromJson(Map<String, dynamic> json) {
    return HvCompileCollision(
      selectorA: json['selectorA'] as String? ?? '',
      selectorB: json['selectorB'] as String? ?? '',
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0,
      hint: json['hint'] as String? ?? '',
    );
  }
}

class HvSkippedServer {
  final String id;
  final String name;
  final String error;

  const HvSkippedServer({
    required this.id,
    required this.name,
    required this.error,
  });

  factory HvSkippedServer.fromJson(Map<String, dynamic> json) {
    return HvSkippedServer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }
}

/// `POST /api/toolkits/compile` success response — the "Compile Tools"
/// result summary (spec T-M11-09).
class HvCompileOutcome {
  final String toolkitId;
  final HvToolkitStats stats;
  final List<HvCompileCollision> collisions;
  final String embedderLabel;
  final String? embedderDegradeReason;
  final List<HvSkippedServer> skippedServers;

  const HvCompileOutcome({
    required this.toolkitId,
    required this.stats,
    this.collisions = const [],
    required this.embedderLabel,
    this.embedderDegradeReason,
    this.skippedServers = const [],
  });

  factory HvCompileOutcome.fromJson(Map<String, dynamic> json) {
    return HvCompileOutcome(
      toolkitId: json['toolkitId'] as String? ?? '',
      stats: HvToolkitStats.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      collisions: ((json['collisions'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvCompileCollision.fromJson(e.cast<String, dynamic>()))
          .toList(),
      embedderLabel: json['embedderLabel'] as String? ?? '',
      embedderDegradeReason: json['embedderDegradeReason'] as String?,
      skippedServers: ((json['skippedServers'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvSkippedServer.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// `422` `CompileError` body: `{error: code, message}`.
class HvCompileError implements Exception {
  final String code;
  final String message;

  const HvCompileError({required this.code, required this.message});

  bool get allServersUnreachable => code == 'all_servers_unreachable';

  @override
  String toString() => message;
}
