import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final foldersAsync = ref.watch(conversationFoldersProvider);
    final selected = ref.watch(historyFolderFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return foldersAsync.when(
      data: (folders) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              _SystemFilterChip(
                label: l10n.all_chats,
                icon: Icons.all_inbox_outlined,
                selected: selected == null,
                isDark: isDark,
                onSelected: (_) => ref
                    .read(historyFolderFilterProvider.notifier)
                    .setFilter(null),
              ),
              const SizedBox(width: 6),
              _SystemFilterChip(
                label: l10n.unfiled_chats,
                icon: Icons.inbox_outlined,
                selected: selected != null && selected.isEmpty,
                isDark: isDark,
                outlined: true,
                onSelected: (_) => ref
                    .read(historyFolderFilterProvider.notifier)
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
                        .read(historyFolderFilterProvider.notifier)
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
                  style: BorderStyle.solid,
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

class _SystemFilterChip extends StatelessWidget {
  const _SystemFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onSelected,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final bool outlined;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = selected
        ? (outlined
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.secondaryContainer)
        : Colors.transparent;
    final borderColor = outlined
        ? (isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC))
        : (selected
            ? theme.colorScheme.secondaryContainer
            : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)));

    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected
            ? theme.colorScheme.onSecondaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: outlined ? FontWeight.normal : FontWeight.w600,
          fontStyle: outlined ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      backgroundColor: bgColor,
      side: BorderSide(color: borderColor),
      onSelected: onSelected,
    );
  }
}
