import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../providers/saved_message_providers.dart';
import 'components/saved_message_folder_bar.dart';

class SavedMessagesScreen extends ConsumerWidget {
  const SavedMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messagesAsync = ref.watch(filteredSavedMessagesProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: topPadding + 8,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE5E5E5),
              ),
            ),
          ),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.saved_messages_title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SavedMessageFolderBar(),
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    l10n.saved_messages_empty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final saved = messages[index];
                  final role = MessageRole.values[saved.roleIndex];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        role == MessageRole.user
                            ? Icons.person_outline
                            : Icons.smart_toy_outlined,
                      ),
                      title: Text(
                        saved.conversationTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        saved.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await ref
                                .read(savedMessagesProvider.notifier)
                                .deleteSavedMessage(saved.id);
                          } else if (value.startsWith('folder:')) {
                            final folderId = value.substring(7);
                            await ref
                                .read(savedMessagesProvider.notifier)
                                .moveToFolder(
                                  saved.id,
                                  folderId.isEmpty ? null : folderId,
                                );
                          }
                        },
                        itemBuilder: (context) {
                          final folders =
                              ref.read(savedMessageFoldersProvider).value ??
                              [];
                          return [
                            ...folders.map(
                              (folder) => PopupMenuItem(
                                value: 'folder:${folder.id}',
                                child: Text(folder.name),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'folder:',
                              child: Text(l10n.unfiled_chats),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.delete),
                            ),
                          ];
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(err.toString())),
          ),
        ),
      ],
    );
  }
}
