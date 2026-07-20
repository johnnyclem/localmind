import 'package:dio/dio.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/network/hypervault_client.dart';
import 'models/hv_chat_result.dart';
import 'models/hv_conversation.dart';
import 'models/hv_message.dart';

/// Thin typed wrapper around [HyperVaultClient] for the M8 server-chat
/// endpoints (`/api/conversations`, `/api/chat`, `/api/messages/[id]/feedback`,
/// `/api/chat-settings`) — mirrors `BackendsApiService`'s role for
/// `/api/backends`.
///
/// `POST /api/chat` can take up to 120s (server `maxDuration`), well past
/// [HyperVaultClient]'s default 30s receive timeout, so that one call goes
/// through [_sendChatRequest], which hits [HyperVaultClient.dio] directly
/// (so auth injection, base URL resolution, and retry/redirect interceptors
/// still apply) with an extended timeout, replicating the client's `{error}`
/// normalization since that's private to [HyperVaultClient].
class HvChatApiService {
  final HyperVaultClient _client;

  HvChatApiService(this._client);

  Future<List<HvConversation>> fetchConversations() async {
    final json = await _client.get<Map<String, dynamic>>('/api/conversations');
    final list = (json['conversations'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(HvConversation.fromJson)
        .toList();
  }

  Future<HvConversationDetail> fetchConversation(String id) async {
    final json = await _client.get<Map<String, dynamic>>('/api/conversations/$id');
    final conversation = HvConversation.fromJson(
      (json['conversation'] as Map<String, dynamic>?) ?? const {},
    );
    final messages = ((json['messages'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HvMessage.fromJson)
        .toList();
    return HvConversationDetail(conversation: conversation, messages: messages);
  }

  Future<HvVisibilityUpdateResult> updateVisibility(
    String id,
    String visibility,
  ) async {
    final json = await _client.patch<Map<String, dynamic>>(
      '/api/conversations/$id',
      data: {'visibility': visibility},
    );
    return HvVisibilityUpdateResult(
      conversation: HvConversation.fromJson(
        (json['conversation'] as Map<String, dynamic>?) ?? const {},
      ),
      shareUrl: json['share_url'] as String?,
      message: json['message'] as String? ?? 'Visibility updated.',
    );
  }

  Future<String> deleteConversation(String id) async {
    final json = await _client.delete<Map<String, dynamic>>('/api/conversations/$id');
    return json['message'] as String? ?? 'Conversation deleted.';
  }

  Future<HvChatResult> sendChat({
    required String backendId,
    required String message,
    String? conversationId,
    bool useRecall = true,
    bool? useSmartContext,
    bool? useDeepMemory,
    bool? useTools,
  }) async {
    final data = <String, dynamic>{
      'backend_id': backendId,
      'message': message,
      'use_recall': useRecall,
    };
    if (conversationId != null) data['conversation_id'] = conversationId;
    if (useSmartContext != null) data['use_smart_context'] = useSmartContext;
    if (useDeepMemory != null) data['use_deep_memory'] = useDeepMemory;
    if (useTools != null) data['use_tools'] = useTools;

    final json = await _sendChatRequest(data);
    return HvChatResult.fromJson(json);
  }

  Future<HvFeedbackResult> setFeedback(String messageId, String? feedback) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/api/messages/$messageId/feedback',
      data: {'feedback': feedback},
    );
    return HvFeedbackResult(
      id: json['id']?.toString() ?? messageId,
      feedback: json['feedback'] as String?,
      message: json['message'] as String? ?? '',
    );
  }

  Future<HvChatSettings> fetchChatSettings() async {
    final json = await _client.get<Map<String, dynamic>>('/api/chat-settings');
    return HvChatSettings.fromJson(json);
  }

  Future<HvChatSettings> updateChatSettings({
    bool? smartContext,
    bool? deepMemory,
  }) async {
    final data = <String, dynamic>{};
    if (smartContext != null) data['smart_context'] = smartContext;
    if (deepMemory != null) data['deep_memory'] = deepMemory;
    final json = await _client.patch<Map<String, dynamic>>(
      '/api/chat-settings',
      data: data,
    );
    return HvChatSettings.fromJson(json);
  }

  Future<Map<String, dynamic>> _sendChatRequest(Map<String, dynamic> data) async {
    late final Response<dynamic> response;
    try {
      response = await _client.dio.request<dynamic>(
        '/api/chat',
        data: data,
        options: Options(
          method: 'POST',
          receiveTimeout: const Duration(seconds: 125),
          sendTimeout: const Duration(seconds: 125),
        ),
      );
    } on DioException catch (e) {
      throw HyperVaultApiException(
        message: e.message ?? 'Network error contacting HyperVault.',
      );
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return response.data as Map<String, dynamic>;
    }
    throw _errorFor(status, response.data);
  }

  HyperVaultApiException _errorFor(int status, dynamic body) {
    String message = 'Request failed ($status).';
    String? code;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is String && err.isNotEmpty) message = err;
      final c = body['code'];
      if (c is String) code = c;
    } else if (body is String && body.isNotEmpty) {
      message = body;
    }
    return HyperVaultApiException(statusCode: status, message: message, code: code);
  }
}
