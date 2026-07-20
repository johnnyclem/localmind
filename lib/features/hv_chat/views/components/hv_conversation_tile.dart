import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../backends/utils/relative_time.dart';
import '../../data/models/hv_conversation.dart';

class HvConversationTile extends StatelessWidget {
  const HvConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  final HvConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = conversation.model != null && conversation.model!.isNotEmpty
        ? '${HvConversation.platformLabel(conversation.sourcePlatform)} · ${conversation.model}'
        : HvConversation.platformLabel(conversation.sourcePlatform);

    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        color: theme.colorScheme.error,
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          color: Colors.white,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: HugeIcon(
          icon: HugeIcons.strokeRoundedBubbleChat,
          color: theme.colorScheme.outline,
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatRelativeTime(conversation.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (conversation.visibility != 'private')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedShare08,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(
          'This permanently deletes "${conversation.title}". This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
