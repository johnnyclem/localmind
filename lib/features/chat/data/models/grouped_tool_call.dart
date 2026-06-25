import 'package:localmind/features/chat/data/tools/tool_event.dart';
import 'package:localmind/features/chat/data/tools/tool_definition.dart';

class GroupedToolCall {
  final String baseId;
  final String toolName;
  final ToolProviderType providerType;
  final String? providerRef;
  final Map<String, dynamic>? arguments;
  final ToolEventStatus status;
  final String? result;
  final String? error;
  final int? durationMs;
  final DateTime timestamp;

  const GroupedToolCall({
    required this.baseId,
    required this.toolName,
    required this.providerType,
    this.providerRef,
    this.arguments,
    required this.status,
    this.result,
    this.error,
    this.durationMs,
    required this.timestamp,
  });
}
