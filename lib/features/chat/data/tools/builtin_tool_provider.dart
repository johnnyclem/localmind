import 'tool_definition.dart';
import 'tool_registry.dart';

class BuiltInToolProvider implements ToolProvider {
  @override
  Future<List<ToolDefinition>> listTools() async => const [
        ToolDefinition(
          name: 'calc.add',
          description: 'Add two numbers',
          inputSchema: {
            'type': 'object',
            'properties': {
              'a': {'type': 'number'},
              'b': {'type': 'number'},
            },
            'required': ['a', 'b'],
          },
          providerType: ToolProviderType.builtIn,
        ),
        ToolDefinition(
          name: 'calc.multiply',
          description: 'Multiply two numbers',
          inputSchema: {
            'type': 'object',
            'properties': {
              'a': {'type': 'number'},
              'b': {'type': 'number'},
            },
            'required': ['a', 'b'],
          },
          providerType: ToolProviderType.builtIn,
        ),
      ];

  @override
  Future<ToolExecutionResult> execute(
    String name,
    Map<String, dynamic> args,
  ) async {
    switch (name) {
      case 'calc.add':
        final sum = (args['a'] as num) + (args['b'] as num);
        return ToolExecutionResult.success(sum.toString());
      case 'calc.multiply':
        final product = (args['a'] as num) * (args['b'] as num);
        return ToolExecutionResult.success(product.toString());
      default:
        return const ToolExecutionResult.failure('Unknown built-in tool');
    }
  }
}
