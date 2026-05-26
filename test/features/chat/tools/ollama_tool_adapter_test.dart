import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/chat/data/tools/adapters/ollama_tool_adapter.dart';
import 'package:localmind/features/chat/data/tools/adapters/tool_transport_adapter.dart';

void main() {
  group('OllamaToolAdapter', () {
    test('parses tool calls from final message', () {
      final adapter = OllamaToolAdapter();
      adapter.consumeDynamicChunk({
        'message': {
          'role': 'assistant',
          'content': '',
          'tool_calls': [
            {
              'id': 'tc_1',
              'function': {'name': 'calc.add', 'arguments': '{"a":1,"b":2}'},
            },
          ],
        },
      });

      final calls = adapter.takeCompletedCalls();
      expect(calls.length, 1);
      expect(calls.single.name, 'calc.add');
      expect(calls.single.arguments['a'], 1);
    });

    test('builds tool result message', () {
      final adapter = OllamaToolAdapter();
      final msg = adapter.buildToolResultMessage(
        call: const ParsedToolCall(
          id: 'tc_1',
          name: 'calc.add',
          arguments: {'a': 1},
        ),
        output: '1',
      );
      expect(msg['role'], 'tool');
      expect(msg['tool_name'], 'calc.add');
    });
  });
}
