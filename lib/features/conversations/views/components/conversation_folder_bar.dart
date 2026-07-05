import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/components/folder_filter_bar.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../providers/conversation_providers.dart';

class ConversationFolderBar extends ConsumerWidget {
  const ConversationFolderBar({super.key});

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
    await ref.read(conversationFoldersProvider.notifier).createFolder(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(conversationFoldersProvider);
    final selected = ref.watch(historyFolderFilterProvider);

    return foldersAsync.when(
      data: (folders) => FolderFilterBar(
        folders: folders
            .map((f) => FolderFilterItem(id: f.id, name: f.name))
            .toList(),
        selectedFolderId: selected,
        onFilterChanged: (id) =>
            ref.read(historyFolderFilterProvider.notifier).setFilter(id),
        onCreateFolder: () => _createFolder(context, ref),
      ),
      loading: () => const SizedBox(height: 44),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
