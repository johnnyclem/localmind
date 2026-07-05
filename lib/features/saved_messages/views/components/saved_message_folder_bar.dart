import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/components/folder_filter_bar.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../providers/saved_message_providers.dart';

class SavedMessageFolderBar extends ConsumerWidget {
  const SavedMessageFolderBar({super.key, this.showCreateFolder = true});

  final bool showCreateFolder;

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
    final foldersAsync = ref.watch(savedMessageFoldersProvider);
    final selected = ref.watch(savedMessageFolderFilterProvider);

    return foldersAsync.when(
      data: (folders) => FolderFilterBar(
        folders: folders
            .map((f) => FolderFilterItem(id: f.id, name: f.name))
            .toList(),
        selectedFolderId: selected,
        onFilterChanged: (id) =>
            ref.read(savedMessageFolderFilterProvider.notifier).setFilter(id),
        onCreateFolder: () => _createFolder(context, ref),
        showCreateFolder: showCreateFolder,
      ),
      loading: () => const SizedBox(height: 44),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
