import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/features/chat/data/models/message.dart';
import 'package:localmind/features/chat/providers/chat_providers.dart';
import '../chat_bubble.dart';

class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.isStreaming,
    required this.onRetry,
    required this.onDelete,
    required this.onEdit,
    this.hasSmartReplies = false,
    this.bottomInset = 0,
  });

  final ScrollController scrollController;
  final List<Message> messages;
  final bool isStreaming;
  final void Function(String) onRetry;
  final void Function(String) onDelete;
  final void Function(String messageId, String currentContent) onEdit;
  final bool hasSmartReplies;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return _MessageListConsumer(
      scrollController: scrollController,
      messages: messages,
      isStreaming: isStreaming,
      onRetry: onRetry,
      onDelete: onDelete,
      onEdit: onEdit,
      hasSmartReplies: hasSmartReplies,
      bottomInset: bottomInset,
    );
  }
}

class _MessageListConsumer extends ConsumerWidget {
  const _MessageListConsumer({
    required this.scrollController,
    required this.messages,
    required this.isStreaming,
    required this.onRetry,
    required this.onDelete,
    required this.onEdit,
    this.hasSmartReplies = false,
    this.bottomInset = 0,
  });

  final ScrollController scrollController;
  final List<Message> messages;
  final bool isStreaming;
  final void Function(String) onRetry;
  final void Function(String) onDelete;
  final void Function(String messageId, String currentContent) onEdit;
  final bool hasSmartReplies;
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamingMessage = ref.watch(
      chatProvider.select((s) => s.streamingMessage),
    );

    return _MessageList(
      scrollController: scrollController,
      messages: messages,
      streamingMessage: streamingMessage,
      isStreaming: isStreaming,
      onRetry: onRetry,
      onDelete: onDelete,
      onEdit: onEdit,
      hasSmartReplies: hasSmartReplies,
      bottomInset: bottomInset,
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.streamingMessage,
    required this.isStreaming,
    required this.onRetry,
    required this.onDelete,
    required this.onEdit,
    this.hasSmartReplies = false,
    this.bottomInset = 0,
  });

  final ScrollController scrollController;
  final List<Message> messages;
  final Message? streamingMessage;
  final bool isStreaming;
  final void Function(String) onRetry;
  final void Function(String) onDelete;
  final void Function(String messageId, String currentContent) onEdit;
  final bool hasSmartReplies;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final allMessages = <Message>[];

    for (final message in messages) {
      if (streamingMessage != null &&
          message.id == streamingMessage!.id &&
          isStreaming) {
        continue;
      }
      allMessages.add(message);
    }

    return ListView.builder(
      controller: scrollController,
      cacheExtent: 1000,
      padding: EdgeInsets.only(
        top: 16,
        bottom: 120 + (hasSmartReplies ? 64 : 0) + bottomInset,
      ),
      itemCount:
          allMessages.length +
          (streamingMessage != null && isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (streamingMessage != null &&
            isStreaming &&
            index == allMessages.length) {
          return ChatBubble(message: streamingMessage!, isStreaming: true);
        }

        final message = allMessages[index];
        final isLast = index == allMessages.length - 1;

        return ChatBubble(
          key: ValueKey(message.id),
          message: message,
          isStreaming:
              isLast && isStreaming && message.id == streamingMessage?.id,
          onRetry: () => onRetry(message.id),
          onDelete: () => onDelete(message.id),
          onEdit: message.role == MessageRole.user
              ? () => onEdit(message.id, message.content)
              : null,
        );
      },
    );
  }
}
