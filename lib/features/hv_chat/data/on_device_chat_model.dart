import 'package:dio/dio.dart';

import '../../../core/models/canonical_message.dart';
import '../../../core/models/enums.dart';
import '../../chat/data/chat_service.dart';
import '../../chat/data/models/chat_parameters.dart';
import '../../chat/data/models/message.dart';
import '../../chat/providers/chat_service_providers.dart' show createChatServiceForServer;
import '../../on_device/data/models/on_device_model.dart';
import '../../on_device/data/on_device_gemma_service.dart';
import '../../on_device/data/on_device_llama_service.dart';
import '../../servers/data/models/server.dart';

/// Thrown by [OnDeviceChatModel.generate] when no on-device model is
/// currently loaded. Callers should catch this and deep-link the user to
/// Settings → Local Models rather than surfacing it as a generic error — this
/// adapter never attempts to auto-load a model.
class NoOnDeviceModelLoadedException implements Exception {
  const NoOnDeviceModelLoadedException();

  @override
  String toString() =>
      'No on-device model is loaded. Set one up in Settings → Local Models.';
}

/// Plain-Dart adapter (no Riverpod dependency) that bridges HyperVault's
/// `CanonicalMessage` wire format onto LocalMind's existing, already-tested
/// on-device inference engines (`OnDeviceGemmaService` / `OnDeviceLlamaService`,
/// exercised today through the older local-chat feature's `ChatService`
/// implementations).
///
/// Rather than duplicating the llama.cpp/Gemma invocation code, this class
/// constructs a throwaway `Server`/`Message`/`ChatParameters` adapter shim and
/// drives the exact same `createChatServiceForServer` factory the existing
/// chat feature uses (`lib/features/chat/providers/chat_service_providers.dart`),
/// simplified for v1: the full `CanonicalMessage` history is flattened into a
/// single "User: …\nAssistant: …" transcript string (one throwaway `Message`)
/// rather than threading through the old feature's multi-message plumbing,
/// and the full response is awaited rather than streamed to the caller.
class OnDeviceChatModel {
  OnDeviceChatModel({
    required OnDeviceGemmaService gemmaService,
    required OnDeviceLlamaService llamaService,
    required OnDeviceModelRuntime? loadedRuntime,
    required String loadedModelId,
  }) : _gemmaService = gemmaService,
       _llamaService = llamaService,
       _loadedRuntime = loadedRuntime,
       _loadedModelId = loadedModelId;

  final OnDeviceGemmaService _gemmaService;
  final OnDeviceLlamaService _llamaService;
  final OnDeviceModelRuntime? _loadedRuntime;
  final String _loadedModelId;

  /// Runs inference against the currently-loaded on-device model. [system]
  /// and [messages] should be exactly what `POST /api/chat/context` returned
  /// (the same context the server itself would have used for `POST
  /// /api/chat`). Awaits the full generated text — no incremental streaming
  /// in v1, matching the thread UI's existing "Thinking…" state.
  Future<String> generate({
    required String system,
    required List<CanonicalMessage> messages,
  }) async {
    final isGemmaLoaded = _gemmaService.isLoaded;
    final isLlamaLoaded = _llamaService.isLoaded;
    if (!isGemmaLoaded && !isLlamaLoaded) {
      throw const NoOnDeviceModelLoadedException();
    }

    // Dio is required by ChatService.forServer's signature but is never
    // touched by either on-device implementation (OnDeviceChatService /
    // OnDeviceLlamaChatService both talk to the native engines directly) —
    // a throwaway instance is safe here.
    final throwawayServer = Server(
      id: 'on-device',
      name: 'On-device',
      type: ServerType.onDevice,
      host: '',
      port: 0,
      createdAt: DateTime.now(),
      lastConnectedAt: DateTime.now(),
    );

    final chatService = createChatServiceForServer(
      server: throwawayServer,
      dio: Dio(),
      onDeviceGemmaService: _gemmaService,
      onDeviceLlamaService: _llamaService,
      loadedOnDeviceRuntime: _loadedRuntime,
    );

    final now = DateTime.now();
    final flattenedPrompt = _flattenTranscript(messages);
    final userMessage = Message(
      id: 'on-device-${now.microsecondsSinceEpoch}',
      conversationId: 'on-device',
      role: MessageRole.user,
      content: flattenedPrompt,
      createdAt: now,
    );

    final params = ChatParameters.defaults().copyWith(
      systemPrompt: system.isNotEmpty ? system : null,
    );

    final buffer = StringBuffer();
    String? errorContent;

    await for (final response in chatService.sendMessage(
      server: throwawayServer,
      modelId: _loadedModelId,
      messages: [userMessage],
      params: params,
    )) {
      switch (response.type) {
        case ChatResponseType.message:
          if (response.content != null) buffer.write(response.content);
          break;
        case ChatResponseType.error:
        case ChatResponseType.timeoutError:
          errorContent = response.content ?? 'On-device generation failed.';
          break;
        case ChatResponseType.done:
        case ChatResponseType.reasoning:
        case ChatResponseType.toolCall:
        case ChatResponseType.invalidToolCall:
        case ChatResponseType.processing:
          break;
      }
    }

    if (errorContent != null) {
      throw StateError(errorContent);
    }
    return buffer.toString().trim();
  }

  /// Concatenates `system` (handled separately via [ChatParameters]) plus a
  /// simple role-labeled transcript of [messages] into one prompt string —
  /// the "reasonable v1 simplification" in place of fully replicating the
  /// existing feature's per-message plumbing for a bridge this thin.
  String _flattenTranscript(List<CanonicalMessage> messages) {
    final buffer = StringBuffer();
    for (final message in messages) {
      switch (message.role) {
        case CanonicalRole.system:
          // Surfaced via ChatParameters.systemPrompt instead.
          break;
        case CanonicalRole.user:
          buffer.writeln('User: ${message.content}');
          break;
        case CanonicalRole.assistant:
          buffer.writeln('Assistant: ${message.content}');
          break;
        case CanonicalRole.tool:
          buffer.writeln('Tool: ${message.content}');
          break;
      }
    }
    buffer.write('Assistant:');
    return buffer.toString();
  }
}
