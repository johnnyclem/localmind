import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../providers/saved_message_providers.dart';

class SavedMessageFolderBar extends ConsumerWidget {
  const SavedMessageFolderBar({super.key});

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.create_folder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.folder_name_hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await ref.read(savedMessageFoldersProvider.notifier).createFolder(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final foldersAsync = ref.watch(savedMessageFoldersProvider);
    final selected = ref.watch(savedMessageFolderFilterProvider);
    final theme = Theme.of(context);

    return foldersAsync.when(
      data: (folders) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              FilterChip(
                avatar: const Icon(Icons.all_inbox_outlined, size: 16),
                label: Text(l10n.all_chats),
                selected: selected == null,
                onSelected: (_) => ref
                    .read(savedMessageFolderFilterProvider.notifier)
                    .setFilter(null),
              ),
              const SizedBox(width: 6),
              FilterChip(
                avatar: const Icon(Icons.inbox_outlined, size: 16),
                label: Text(l10n.unfiled_chats),
                selected: selected != null && selected.isEmpty,
                onSelected: (_) => ref
                    .read(savedMessageFolderFilterProvider.notifier)
                    .setFilter(''),
              ),
              ...folders.map(
                (folder) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: selected == folder.id
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.primary,
                    ),
                    label: Text(folder.name),
                    selected: selected == folder.id,
                    showCheckmark: false,
                    onSelected: (_) => ref
                        .read(savedMessageFolderFilterProvider.notifier)
                        .setFilter(folder.id),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ActionChip(
                avatar: Icon(
                  Icons.create_new_folder_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                label: Text(l10n.new_folder),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                onPressed: () => _createFolder(context, ref),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 44),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
