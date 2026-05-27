import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/features/chat/data/mcp_server_manager.dart';
import 'package:localmind/features/chat/data/models/message.dart';
import 'package:localmind/features/chat/data/tools/builtin_tool_provider.dart';
import 'package:localmind/features/chat/data/tools/mcp_tool_provider.dart';
import 'package:localmind/features/chat/data/tools/tool_definition.dart';
import 'package:localmind/features/chat/data/tools/tool_event.dart';
import 'package:localmind/features/chat/data/tools/tool_registry.dart';

void main() {
  test('Message preserves toolEvents in copyWith', () {
    final msg = Message(
      id: 'm1',
      conversationId: 'c1',
      role: MessageRole.assistant,
      content: 'hi',
      createdAt: DateTime(2026, 1, 1),
      toolEvents: [
        ToolEvent.requested(
          eventId: 'e1',
          toolName: 'calc.add',
          providerType: ToolProviderType.builtIn,
        ),
      ],
    );

    expect(msg.copyWith().toolEvents!.length, 1);
  });

  test('registry resolves built-in tools with allow-list filtering', () async {
    final registry = ToolRegistry(providers: [BuiltInToolProvider()]);
    final tools = await registry.listTools(allowedTools: {'calc.add'});
    expect(tools.map((t) => t.name), ['calc.add']);
  });

  test('registry executes tool from correct provider', () async {
    final registry = ToolRegistry(providers: [BuiltInToolProvider()]);
    final result = await registry.execute('calc.add', {'a': 1, 'b': 2});
    expect(result.success, true);
    expect(result.output, '3');
  });

  test('registry returns failure for unknown tool', () async {
    final registry = ToolRegistry(providers: [BuiltInToolProvider()]);
    final result = await registry.execute('unknown.tool', {});
    expect(result.success, false);
  });

  test('registry exposes and executes example MCP tools', () async {
    final manager = McpServerManager()..addExampleServer();
    final registry = ToolRegistry(
      providers: [
        BuiltInToolProvider(),
        McpToolProvider(serverManager: manager),
      ],
    );

    final tools = await registry.listTools();
    expect(tools.any((tool) => tool.name == 'example.echo'), true);

    final result = await registry.execute('example.word_count', {
      'text': 'MCP tools are available',
    });
    expect(result.success, true);
    expect(result.output, '4');
  });
}
