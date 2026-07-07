import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:localmind/core/providers/app_providers.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:localmind/core/services/export_choice_dialog.dart';
import 'package:localmind/features/conversations/data/models/conversation.dart';
import 'package:localmind/features/chat/views/components/chat_settings_sheet.dart';
import 'package:localmind/features/chat/providers/chat_mcp_providers.dart';
import 'package:localmind/features/chat/providers/chat_providers.dart';
import 'package:localmind/features/chat/data/export_service.dart';

class ScreenAppBar extends ConsumerWidget {
  const ScreenAppBar({
    super.key,
    required this.activeConversation,
    required this.isDark,
    required this.hasPersonas,
    required this.isTemporary,
    required this.hasMessages,
    required this.onMenuAction,
    required this.onPersonaPicker,
    required this.onChatModeAction,
  });

  final Conversation? activeConversation;
  final bool isDark;
  final bool hasPersonas;
  final bool isTemporary;
  final bool hasMessages;
  final void Function(String) onMenuAction;
  final VoidCallback onPersonaPicker;
  final VoidCallback onChatModeAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final mcpConfig = ref.watch(chatMcpConfigProvider);
    final isMcpEnabled = settings.mcpEnabled && mcpConfig.enabled;
    final messageSelectionMode = ref.watch(messageSelectionModeProvider);
    final selectedMessageIds = ref.watch(selectedMessageIdsProvider);

    if (messageSelectionMode) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  ref.read(messageSelectionModeProvider.notifier).disable(),
            ),
            Expanded(
              child: Text(
                l10n.selected_count(selectedMessageIds.length),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: l10n.export_conversation,
              onPressed: selectedMessageIds.isEmpty
                  ? null
                  : () => _shareSelectedMessages(
                      context,
                      ref,
                      selectedMessageIds,
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: l10n.delete,
              onPressed: selectedMessageIds.isEmpty
                  ? null
                  : () => _deleteSelectedMessages(
                      context,
                      ref,
                      selectedMessageIds,
                    ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          ShadResponsiveBuilder(
            builder: (context, breakpoint) {
              final isDesktop =
                  breakpoint >= ShadTheme.of(context).breakpoints.md;
              if (isDesktop) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AutoSizeText(
              _appBarTitle(l10n),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedFilterHorizontal,
                  size: 24,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                onPressed: () =>
                    showChatSettingsSheet(context, initialTab: 'parameters'),
                tooltip: l10n.chat_parameters_tooltip,
              ),
              PositionedDirectional(
                top: 4,
                end: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isMcpEnabled ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedTools,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          ChatModeIconButton(
            hasMessages: hasMessages,
            isTemporary: isTemporary,
            isDark: isDark,
            onPressed: onChatModeAction,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: onMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new_chat',
                child: ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l10n.nav_new_chat),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (activeConversation != null && !isTemporary) ...[
                PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: const Icon(Icons.drive_file_rename_outline),
                    title: Text(l10n.rename_conversation),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'move_to_folder',
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(l10n.move_to_folder),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              if (hasMessages) ...[
                PopupMenuItem(
                  value: 'export_chat',
                  child: ListTile(
                    leading: const Icon(Icons.upload_outlined),
                    title: Text(l10n.export_conversation),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'share_chat',
                  child: ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: Text(l10n.share_conversation),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              PopupMenuItem(
                value: 'persona',
                child: ListTile(
                  leading: Icon(
                    hasPersonas ? Icons.swap_horiz : Icons.smart_toy_outlined,
                  ),
                  title: Text(
                    hasPersonas ? l10n.change_persona : l10n.set_persona,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.clear_conversation),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _appBarTitle(AppLocalizations l10n) {
    if (isTemporary) return l10n.temporary_chat;
    if (activeConversation?.title.isNotEmpty == true) {
      final title = activeConversation!.title;
      if (title.length > 30) {
        return '${title.substring(0, 30)}...';
      }
      return title;
    }
    return l10n.nav_new_chat;
  }

  Future<void> _shareSelectedMessages(
    BuildContext context,
    WidgetRef ref,
    Set<String> selectedIds,
  ) async {
    final messages = ref
        .read(chatProvider)
        .messages
        .where((m) => selectedIds.contains(m.id))
        .toList();
    if (messages.isEmpty) return;
    final text = ExportService.exportAsText(messages);
    ref.read(messageSelectionModeProvider.notifier).disable();
    if (!context.mounted) return;
    await showExportChoiceDialog(context, content: text);
  }

  void _deleteSelectedMessages(
    BuildContext context,
    WidgetRef ref,
    Set<String> selectedIds,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.delete_message_title),
          content: Text(l10n.selected_count(selectedIds.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                for (final id in selectedIds) {
                  await ref.read(chatProvider.notifier).deleteMessage(id);
                }
                ref.read(messageSelectionModeProvider.notifier).disable();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }
}

class ChatModeIconButton extends StatelessWidget {
  const ChatModeIconButton({
    super.key,
    required this.hasMessages,
    required this.isTemporary,
    required this.isDark,
    required this.onPressed,
  });

  final bool hasMessages;
  final bool isTemporary;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showGhost = !hasMessages || isTemporary;
    final ghostActive = isTemporary;

    if (showGhost) {
      final activeColor = isDark
          ? const Color(0xFFE6C35C)
          : const Color(0xFF9A7B1A);
      final inactiveColor = isDark ? Colors.white54 : Colors.black45;

      return IconButton(
        onPressed: onPressed,
        tooltip: ghostActive
            ? l10n.exit_temporary_chat_title
            : l10n.temporary_chat,
        icon: ghostActive
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.ghost, size: 20, color: activeColor),
              )
            : Icon(LucideIcons.ghost, size: 22, color: inactiveColor),
      );
    }

    return IconButton(
      onPressed: onPressed,
      tooltip: l10n.nav_new_chat,
      icon: Icon(
        Icons.add_comment_outlined,
        size: 22,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }
}
