import 'dart:async';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';
import '../../servers/data/models/server.dart';
import 'chat_service.dart';
import 'models/chat_parameters.dart';
import 'models/message.dart';

class TitleGenerationService {
  static const _defaultTitle = 'New Chat';

  Future<String?> generateTitleWithLLM({
    required ChatService chatService,
    required Server server,
    required String modelId,
    required List<Message> messages,
    required ChatParameters params,
  }) async {
    if (messages.isEmpty) return null;

    final promptMessage = Message(
      id: 'title-generation-prompt',
      conversationId: messages.first.conversationId,
      role: MessageRole.user,
      content:
          'Based on the conversation above, generate a short, descriptive title for this chat. '
          'Return ONLY the title text — no quotes, markdown, labels, or explanation. '
          'Keep it under 8 words.',
      createdAt: DateTime.now(),
    );

    final titleParams = params.copyWith(
      temperature: 0.3,
      maxTokens: 32,
      systemPrompt:
          'You generate concise chat titles. Output only the title string, nothing else.',
    );

    try {
      final completer = Completer<String>();
      var accumulatedContent = '';

      final stream = chatService.sendMessage(
        server: server,
        modelId: modelId,
        messages: [...messages, promptMessage],
        params: titleParams,
      );

      StreamSubscription? subscription;
      subscription = stream.listen(
        (response) {
          if (response.type == ChatResponseType.message &&
              response.content != null) {
            accumulatedContent += response.content!;
          } else if (response.type == ChatResponseType.done) {
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.complete(accumulatedContent);
            }
          } else if (response.type == ChatResponseType.error) {
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.completeError(
                response.content ?? 'Unknown streaming error',
              );
            }
          }
        },
        onError: (err) {
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.completeError(err);
          }
        },
        onDone: () {
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.complete(accumulatedContent);
          }
        },
        cancelOnError: true,
      );

      final rawResponse = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          subscription?.cancel();
          return accumulatedContent;
        },
      );

      return _parseTitle(rawResponse);
    } catch (e) {
      Log.warning('LLM title generation failed: $e');
      return null;
    }
  }

  String truncateFirstMessageTitle(String content, {int maxLength = 50}) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return _defaultTitle;
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}...';
  }

  String _parseTitle(String text) {
    var title = text.trim();
    if (title.isEmpty) return '';

    title = title.replaceFirst(
      RegExp(r'^(title|chat title|subject)\s*:\s*', caseSensitive: false),
      '',
    );
    title = title.replaceAll(RegExp(r'```.*?```', dotAll: true), '');
    title = title.replaceAll('`', '');
    title = title.split('\n').first.trim();

    if ((title.startsWith('"') && title.endsWith('"')) ||
        (title.startsWith("'") && title.endsWith("'"))) {
      title = title.substring(1, title.length - 1).trim();
    }

    if (title.length > 80) {
      title = '${title.substring(0, 80).trim()}...';
    }

    return title;
  }
}
