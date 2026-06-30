import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../chat/providers/chat_providers.dart';
import '../../data/models/conversation.dart';
import '../../providers/conversation_providers.dart';
import 'conversation_tile.dart';
import 'date_section_header.dart';

class ConversationList extends ConsumerWidget {
  const ConversationList({
    super.key,
    required this.groupedConversations,
    required this.activeConversation,
  });

  final Map<String, List<Conversation>> groupedConversations;
  final Conversation? activeConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sectionOrder = [
      l10n.pinned_section,
      l10n.today_section,
      l10n.yesterday_section,
      l10n.previous_7_days,
      l10n.previous_30_days,
      l10n.older_section,
    ];
    final sortedSections = groupedConversations.keys.toList()
      ..sort((a, b) {
        final aIndex = sectionOrder.indexOf(a);
        final bIndex = sectionOrder.indexOf(b);
        return aIndex.compareTo(bIndex);
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: sortedSections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sortedSections[sectionIndex];
        final conversations = groupedConversations[section]!;

        if (section == l10n.pinned_section && conversations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateSectionHeader(title: section),
            ...conversations.map((conversation) {
              return ConversationTile(
                conversation: conversation,
                isActive: activeConversation?.id == conversation.id,
                onTap: () {
                  ref
                      .read(chatProvider.notifier)
                      .loadConversation(conversation);
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.pop(context);
                  }
                  context.go(AppRoutes.home);
                },
                onRename: () {
                  _showRenameDialog(context, ref, l10n, conversation);
                },
                onTogglePin: () {
                  ref
                      .read(conversationsProvider.notifier)
                      .togglePin(conversation.id);
                },
                onDelete: () {
                  _showDeleteConfirmation(context, ref, l10n, conversation);
                },
                onDuplicate: () {
                  ref
                      .read(conversationsProvider.notifier)
                      .duplicateConversation(conversation.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.duplicate_chat_success)),
                  );
                },
                onMoveToFolder: () {
                  _showMoveToFolderSheet(context, ref, l10n, conversation);
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Conversation conversation,
  ) {
    final controller = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.rename_conversation),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.enter_new_title,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  ref
                      .read(conversationsProvider.notifier)
                      .renameConversation(conversation.id, newTitle);
                }
                Navigator.pop(context);
              },
              child: Text(l10n.rename),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Conversation conversation,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.delete_conversation_title),
          content: Text(l10n.delete_conversation_body(conversation.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(conversationsProvider.notifier)
                    .deleteConversation(conversation.id);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  void _showMoveToFolderSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Conversation conversation,
  ) {
    final folders = ref.read(conversationFoldersProvider).value ?? [];

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: Text(l10n.remove_from_folder),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(conversationsProvider.notifier)
                      .moveConversationToFolder(conversation.id, null);
                },
              ),
              ...folders.map(
                (folder) => ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(conversationsProvider.notifier)
                        .moveConversationToFolder(conversation.id, folder.id);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
