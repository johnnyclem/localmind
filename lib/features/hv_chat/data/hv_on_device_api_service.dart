import '../../../core/network/hypervault_client.dart';
import 'models/hv_on_device_result.dart';

/// Thin typed wrapper around [HyperVaultClient] for the M9 on-device
/// inference endpoints (`/api/chat/context`, `/api/chat/turns`) — mirrors
/// [HvChatApiService]'s role for `/api/chat` but splits context assembly from
/// persistence so an on-device model can run the inference step locally
/// instead of the server.
class HvOnDeviceApiService {
  final HyperVaultClient _client;

  HvOnDeviceApiService(this._client);

  /// `POST /api/chat/context` — assembles the exact same system prompt +
  /// history the server would use for `POST /api/chat`, so a locally-run
  /// model can generate against identical inputs.
  Future<HvContextResult> assembleContext({
    required String message,
    String? conversationId,
    bool useRecall = true,
    bool? useSmartContext,
    bool? useDeepMemory,
  }) async {
    final data = <String, dynamic>{'message': message, 'use_recall': useRecall};
    if (conversationId != null) data['conversation_id'] = conversationId;
    if (useSmartContext != null) data['use_smart_context'] = useSmartContext;
    if (useDeepMemory != null) data['use_deep_memory'] = useDeepMemory;

    final json = await _client.post<Map<String, dynamic>>(
      '/api/chat/context',
      data: data,
    );
    return HvContextResult.fromJson(json);
  }

  /// `POST /api/chat/turns` — persists a turn generated on-device. Creates
  /// the conversation when [conversationId] is omitted, mirroring
  /// `POST /api/chat`'s first-turn behavior.
  Future<HvTurnResult> persistTurn({
    required String userMessage,
    required String assistantContent,
    String? conversationId,
    String? title,
    String? model,
  }) async {
    final data = <String, dynamic>{
      'user_message': userMessage,
      'assistant_content': assistantContent,
    };
    if (conversationId != null) data['conversation_id'] = conversationId;
    if (title != null) data['title'] = title;
    if (model != null) data['model'] = model;

    final json = await _client.post<Map<String, dynamic>>(
      '/api/chat/turns',
      data: data,
    );
    return HvTurnResult.fromJson(json);
  }
}
