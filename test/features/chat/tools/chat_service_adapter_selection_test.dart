import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/features/chat/data/chat_service.dart';
import 'package:localmind/features/chat/data/tools/adapters/ollama_tool_adapter.dart';
import 'package:localmind/features/chat/data/tools/adapters/openai_tool_adapter.dart';
import 'package:localmind/features/chat/data/tools/adapters/openrouter_tool_adapter.dart';

void main() {
  group('createAdapterForServerType', () {
    test('uses OpenAI adapter for OpenAI-compatible servers', () {
      final adapter = createAdapterForServerType(ServerType.openAICompatible);
      expect(adapter, isA<OpenAiToolAdapter>());
    });

    test('uses OpenRouter adapter for OpenRouter servers', () {
      final adapter = createAdapterForServerType(ServerType.openRouter);
      expect(adapter, isA<OpenRouterToolAdapter>());
    });

    test('uses Ollama adapter for Ollama servers', () {
      final adapter = createAdapterForServerType(ServerType.ollama);
      expect(adapter, isA<OllamaToolAdapter>());
    });
  });
}
