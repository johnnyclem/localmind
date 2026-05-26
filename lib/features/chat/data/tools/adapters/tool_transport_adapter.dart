import 'package:localmind/features/chat/data/tools/tool_definition.dart';

class ParsedToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ParsedToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

abstract class ToolTransportAdapter {
  Map<String, dynamic> buildToolDefinitionPayload(List<ToolDefinition> tools);
  void consumeDynamicChunk(Map<String, dynamic> chunk);
  List<ParsedToolCall> takeCompletedCalls();
  Map<String, dynamic> buildToolResultMessage({
    required ParsedToolCall call,
    required String output,
  });
}
