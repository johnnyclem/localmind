import '../../../../core/models/enums.dart';

class MessageSearchHit {
  const MessageSearchHit({
    required this.messageId,
    required this.conversationId,
    required this.conversationTitle,
    required this.snippet,
    required this.role,
  });

  final String messageId;
  final String conversationId;
  final String conversationTitle;
  final String snippet;
  final MessageRole role;
}
