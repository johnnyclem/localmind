import '../../../core/models/enums.dart';
import '../../chat/data/chat_service.dart' show ChatResponse, ChatResponseType;
import '../../chat/data/models/chat_parameters.dart';
import '../../chat/data/models/message.dart';
import '../../hypervault/data/hypervault_api_client.dart';
import '../../hypervault/data/models/hv_api_error.dart';
import 'models/hv_chat_context.dart';

/// A caller-supplied on-device generation call, so this file stays free of
/// any dependency on the specific on-device runtime (gemma/llama.cpp) — the
/// caller wires it up from LocalMind's existing `ChatService.sendMessage`
/// (see `createChatServiceForServer` in
/// `chat/providers/chat_service_providers.dart`), reusing that inference
/// path rather than reimplementing it here.
typedef HvOnDeviceGenerate =
    Stream<ChatResponse> Function({
      required String modelId,
      required List<Message> messages,
      required ChatParameters params,
    });

/// Bridges HyperVault's server-side context assembly into LocalMind's
/// on-device inference: `POST /api/chat/context` (docs/mobile/prd/
/// 09-on-device-inference.md, api-contract.md) supplies the exact same
/// system prompt + wire history the server itself would use — wiki recall,
/// smart-context compaction, deep-memory GraphRAG — so an on-device model
/// answers with the user's full HyperVault memory in context, and
/// `POST /api/chat/turns` persists the turn the on-device model produced.
/// Talks only through [HyperVaultApiClient] — never constructs its own Dio.
class HyperVaultOnDeviceBridgeService {
  final HyperVaultApiClient _client;

  const HyperVaultOnDeviceBridgeService(this._client);

  Future<HvChatContextResult> fetchContext({
    required String message,
    String? conversationId,
    bool useRecall = true,
    bool? useSmartContext,
    bool? useDeepMemory,
  }) async {
    final json = await _client.post(
      '/api/chat/context',
      body: {
        'message': message,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversation_id': conversationId,
        'use_recall': useRecall,
        'use_smart_context': ?useSmartContext,
        'use_deep_memory': ?useDeepMemory,
      },
    );
    return HvChatContextResult.fromJson(json);
  }

  Future<HvTurnResult> persistTurn({
    required String userMessage,
    required String assistantContent,
    String? conversationId,
    String? title,
    String? model,
  }) async {
    final json = await _client.post(
      '/api/chat/turns',
      body: {
        'user_message': userMessage,
        'assistant_content': assistantContent,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversation_id': conversationId,
        if (title != null && title.isNotEmpty) 'title': title,
        if (model != null && model.isNotEmpty) 'model': model,
      },
    );
    return HvTurnResult.fromJson(json);
  }

  /// Runs one full context → on-device generate → turns round trip.
  /// Tool-free by design (spec §4.3): the on-device path never dispatches
  /// HyperVault tools.
  Future<HvBridgeRoundTripResult> runRoundTrip({
    required String message,
    required String onDeviceModelId,
    required HvOnDeviceGenerate generate,
    String? conversationId,
    bool useRecall = true,
    bool? useSmartContext,
    bool? useDeepMemory,
  }) async {
    final context = await fetchContext(
      message: message,
      conversationId: conversationId,
      useRecall: useRecall,
      useSmartContext: useSmartContext,
      useDeepMemory: useDeepMemory,
    );

    final wireMessages = context.messages
        .asMap()
        .entries
        .map(
          (entry) => Message(
            id: 'hv-ctx-${entry.key}',
            conversationId: context.conversationId ?? 'pending',
            role: _roleFromWire(entry.value.role),
            content: entry.value.content,
            createdAt:
                DateTime.tryParse(entry.value.createdAt ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();

    final params = ChatParameters.defaults().copyWith(
      systemPrompt: context.system.isEmpty ? null : context.system,
    );

    final buffer = StringBuffer();
    String? errorText;
    await for (final response in generate(
      modelId: onDeviceModelId,
      messages: wireMessages,
      params: params,
    )) {
      if (response.type == ChatResponseType.message &&
          response.content != null) {
        buffer.write(response.content);
      } else if (response.type == ChatResponseType.error) {
        errorText = response.content ?? 'On-device generation failed.';
      } else if (response.type == ChatResponseType.done) {
        break;
      }
    }

    if (errorText != null) {
      throw HvApiError(error: errorText);
    }
    final assistantText = buffer.toString().trim();
    if (assistantText.isEmpty) {
      throw const HvApiError(
        error: 'The on-device model produced no text for this turn.',
      );
    }

    final turn = await persistTurn(
      userMessage: message,
      assistantContent: assistantText,
      conversationId: context.conversationId,
      model: onDeviceModelId,
    );

    return HvBridgeRoundTripResult(
      context: context,
      assistantText: assistantText,
      turn: turn,
    );
  }

  MessageRole _roleFromWire(String role) {
    switch (role) {
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      case 'tool':
        return MessageRole.tool;
      default:
        return MessageRole.user;
    }
  }
}

class HvBridgeRoundTripResult {
  final HvChatContextResult context;
  final String assistantText;
  final HvTurnResult turn;

  const HvBridgeRoundTripResult({
    required this.context,
    required this.assistantText,
    required this.turn,
  });
}
