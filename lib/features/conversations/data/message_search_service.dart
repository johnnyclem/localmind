import '../../../core/models/enums.dart';
import '../../../core/storage/objectbox_store.dart';
import '../../../objectbox.g.dart';
import 'models/message_search_hit.dart';

class MessageSearchService {
  const MessageSearchService();

  List<MessageSearchHit> searchMessages(
    ObjectBoxStore db, {
    required String query,
    int limit = 50,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];

    final conversations = db.conversationBox.getAll();
    final titleById = {
      for (final conversation in conversations)
        conversation.id: conversation.title,
    };

    final hits = <MessageSearchHit>[];
    final messageQuery = db.messageBox
        .query(
          MessageEntity_.content.contains(
            normalizedQuery,
            caseSensitive: false,
          ),
        )
        .build();
    final messages = messageQuery.find();
    messageQuery.close();

    for (final entity in messages) {
      if (!entity.content.toLowerCase().contains(normalizedQuery)) continue;

      final title = titleById[entity.conversationUid] ?? 'Chat';
      final content = entity.content;
      final index = content.toLowerCase().indexOf(normalizedQuery);
      final start = index > 40 ? index - 40 : 0;
      final end = (index + normalizedQuery.length + 40).clamp(0, content.length);
      var snippet = content.substring(start, end);
      if (start > 0) snippet = '…$snippet';
      if (end < content.length) snippet = '$snippet…';

      hits.add(
        MessageSearchHit(
          messageId: entity.id,
          conversationId: entity.conversationUid,
          conversationTitle: title,
          snippet: snippet,
          role: MessageRole.values[entity.roleIndex],
        ),
      );
      if (hits.length >= limit) break;
    }
    return hits;
  }
}
