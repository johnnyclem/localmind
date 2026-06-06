import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/features/chat/data/chat_service.dart';
import 'package:localmind/features/chat/data/models/message.dart';
import 'package:localmind/features/chat/data/models/chat_parameters.dart';
import 'package:localmind/features/chat/data/tools/tool_definition.dart';
import 'package:localmind/features/chat/data/tools/adapters/ollama_tool_adapter.dart';
import 'package:localmind/features/chat/data/tools/adapters/openai_tool_adapter.dart';
import 'package:localmind/features/chat/data/tools/adapters/openrouter_tool_adapter.dart';
import 'package:localmind/features/servers/data/models/server.dart';

class StreamInterceptor extends Interceptor {
  final List<String> lines;
  StreamInterceptor(this.lines);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final controller = StreamController<Uint8List>();
    handler.resolve(Response(
      requestOptions: options,
      data: ResponseBody(
        controller.stream,
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
      statusCode: 200,
    ));

    // Emit lines asynchronously
    Future.microtask(() async {
      for (final line in lines) {
        controller.add(Uint8List.fromList(utf8.encode('$line\n')));
        await Future.delayed(const Duration(milliseconds: 1));
      }
      await controller.close();
    });
  }
}

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

  group('ChatService implementation tool call adapter integration', () {
    test('OpenAICompatibleChatService uses OpenAiToolAdapter and parses OpenAI stream tool calls', () async {
      final lines = [
        'data: {"choices": [{"delta": {"tool_calls": [{"index": 0, "id": "call_openai_1", "type": "function", "function": {"name": "calc.add", "arguments": ""}}]}}]}',
        'data: {"choices": [{"delta": {"tool_calls": [{"index": 0, "function": {"arguments": "{\\"a\\":1,\\"b\\":2}"}}]}}]}',
        'data: [DONE]'
      ];

      final dio = Dio()..interceptors.add(StreamInterceptor(lines));
      final service = OpenAICompatibleChatService(dio);

      final server = Server(
        id: 'test-openai',
        name: 'Test OpenAI',
        type: ServerType.openAICompatible,
        host: 'localhost',
        port: 8080,
        createdAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );

      final responseStream = service.sendMessage(
        server: server,
        modelId: 'test-model',
        messages: [
          Message(
            id: 'msg_1',
            conversationId: 'conv_1',
            role: MessageRole.user,
            content: 'hello',
            createdAt: DateTime.now(),
          )
        ],
        params: ChatParameters.defaults(),
        tools: [
          const ToolDefinition(
            name: 'calc.add',
            description: 'Add two numbers',
            inputSchema: {'type': 'object'},
            providerType: ToolProviderType.builtIn,
          )
        ],
      );

      final responses = await responseStream.toList();
      final toolCalls = responses
          .where((r) => r.type == ChatResponseType.toolCall)
          .map((r) => r.toolCall)
          .toList();

      expect(toolCalls, isNotEmpty);
      expect(toolCalls.first!.tool, 'calc.add');
      expect(toolCalls.first!.arguments['a'], 1);
      expect(toolCalls.first!.arguments['b'], 2);
    });

    test('OllamaChatService uses OllamaToolAdapter and parses Ollama stream tool calls', () async {
      final lines = [
        '{"message": {"tool_calls": [{"id": "call_ollama_1", "function": {"name": "calc.multiply", "arguments": "{\\"a\\":5,\\"b\\":6}"}}]}}',
        '{"done": true}'
      ];

      final dio = Dio()..interceptors.add(StreamInterceptor(lines));
      final service = OllamaChatService(dio);

      final server = Server(
        id: 'test-ollama',
        name: 'Test Ollama',
        type: ServerType.ollama,
        host: 'localhost',
        port: 11434,
        createdAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );

      final responseStream = service.sendMessage(
        server: server,
        modelId: 'test-model',
        messages: [
          Message(
            id: 'msg_2',
            conversationId: 'conv_2',
            role: MessageRole.user,
            content: 'hello',
            createdAt: DateTime.now(),
          )
        ],
        params: ChatParameters.defaults(),
        tools: [
          const ToolDefinition(
            name: 'calc.multiply',
            description: 'Multiply two numbers',
            inputSchema: {'type': 'object'},
            providerType: ToolProviderType.builtIn,
          )
        ],
      );

      final responses = await responseStream.toList();
      final toolCalls = responses
          .where((r) => r.type == ChatResponseType.toolCall)
          .map((r) => r.toolCall)
          .toList();

      expect(toolCalls, isNotEmpty);
      expect(toolCalls.first!.tool, 'calc.multiply');
      expect(toolCalls.first!.arguments['a'], 5);
      expect(toolCalls.first!.arguments['b'], 6);
    });
  });
}
