import 'tool_definition.dart';

abstract class ToolProvider {
  Future<List<ToolDefinition>> listTools();
  Future<ToolExecutionResult> execute(String name, Map<String, dynamic> args);
}

class ToolRegistry {
  final List<ToolProvider> providers;

  ToolRegistry({required this.providers});

  Future<List<ToolDefinition>> listTools({Set<String>? allowedTools}) async {
    final all = <ToolDefinition>[];
    for (final provider in providers) {
      all.addAll(await provider.listTools());
    }
    if (allowedTools == null || allowedTools.isEmpty) return all;
    return all.where((t) => allowedTools.contains(t.name)).toList();
  }

  Future<ToolExecutionResult> execute(
    String name,
    Map<String, dynamic> args,
  ) async {
    for (final provider in providers) {
      final tools = await provider.listTools();
      if (tools.any((t) => t.name == name)) {
        return provider.execute(name, args);
      }
    }
    return const ToolExecutionResult.failure('Tool not found');
  }
}
