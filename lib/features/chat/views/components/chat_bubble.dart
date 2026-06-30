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
    required this.allMessages,
    this.onCopy,
    this.onRetry,
    this.onDelete,
    this.onEdit,
    this.onBranch,
    this.onContinue,
    this.onModelTap,
    this.onCycleVariant,
    this.onSave,
    this.isStreaming = false,
  });

  final Message message;
  final List<Message> allMessages;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onBranch;
  final VoidCallback? onContinue;
  final VoidCallback? onModelTap;
  final void Function(int direction)? onCycleVariant;
  final void Function(Message message)? onSave;
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
            allMessages: allMessages,
            onCopy: onCopy,
            onDelete: onDelete,
            onEdit: onEdit,
            onBranch: onBranch,
            onCycleVariant: onCycleVariant,
            onSave: onSave,
          ),
        );
      case MessageRole.assistant:
        return AnimatedBubble(
          alignment: AlignmentDirectional.centerStart,
          child: AssistantBubble(
            message: message,
            allMessages: allMessages,
            onCopy: onCopy,
            onRetry: onRetry,
            onDelete: onDelete,
            onEdit: onEdit,
            onBranch: onBranch,
            onContinue: onContinue,
            onModelTap: onModelTap,
            onCycleVariant: onCycleVariant,
            onSave: onSave,
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
