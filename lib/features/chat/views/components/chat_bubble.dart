import 'package:flutter/material.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/features/chat/data/models/message.dart';
import 'chat_bubble/animated_bubble.dart';
import 'chat_bubble/user_bubble.dart';
import 'chat_bubble/assistant_bubble.dart';
import 'chat_bubble/system_bubble.dart';
import 'chat_bubble/tool_bubble/tool_bubble.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onRetry,
    this.onDelete,
    this.onEdit,
    this.isStreaming = false,
  });

  final Message message;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: _buildBubble(context));
  }

  Widget _buildBubble(BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return AnimatedBubble(
          alignment: AlignmentDirectional.centerEnd,
          child: UserBubble(
            message: message,
            onCopy: onCopy,
            onDelete: onDelete,
            onEdit: onEdit,
          ),
        );
      case MessageRole.assistant:
        return AnimatedBubble(
          alignment: AlignmentDirectional.centerStart,
          child: AssistantBubble(
            message: message,
            onCopy: onCopy,
            onRetry: onRetry,
            onDelete: onDelete,
            isStreaming: isStreaming,
          ),
        );
      case MessageRole.system:
        return AnimatedBubble(
          alignment: AlignmentDirectional.center,
          child: SystemBubble(message: message),
        );
      case MessageRole.tool:
        return AnimatedBubble(
          alignment: AlignmentDirectional.centerStart,
          child: ToolBubble(message: message),
        );
    }
  }
}
