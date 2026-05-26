class ServerExecutedToolCall {
  final String name;
  final Map<String, dynamic> arguments;
  final String output;
  const ServerExecutedToolCall({required this.name, required this.arguments, required this.output});
}

class LmStudioToolAdapter {
  final List<ServerExecutedToolCall> _completedCalls = [];
  String? _currentTool;
  Map<String, dynamic> _currentArgs = {};

  void consumeEvent(String eventType, Map<String, dynamic> data) {
    switch (eventType) {
      case 'tool_call.start':
        _currentTool = data['tool'] as String?;
        _currentArgs = {};
        break;
      case 'tool_call.arguments':
        final args = data['arguments'] as Map<String, dynamic>?;
        if (args != null) {
          _currentArgs = args;
        }
        break;
      case 'tool_call.success':
        final tool = data['tool'] as String? ?? _currentTool;
        final args = data['arguments'] as Map<String, dynamic>? ?? _currentArgs;
        final output = data['output'] as String? ?? '';
        if (tool != null) {
          _completedCalls.add(ServerExecutedToolCall(
            name: tool,
            arguments: args,
            output: output,
          ));
        }
        _currentTool = null;
        _currentArgs = {};
        break;
      case 'tool_call.failure':
        final tool = data['tool'] as String? ?? _currentTool;
        final args = data['arguments'] as Map<String, dynamic>? ?? _currentArgs;
        final reason = data['reason'] as String? ?? 'Tool execution failed';
        if (tool != null) {
          _completedCalls.add(ServerExecutedToolCall(
            name: tool,
            arguments: args,
            output: reason,
          ));
        }
        _currentTool = null;
        _currentArgs = {};
        break;
    }
  }

  List<ServerExecutedToolCall> takeServerExecutedCalls() {
    final calls = List<ServerExecutedToolCall>.from(_completedCalls);
    _completedCalls.clear();
    return calls;
  }
}
