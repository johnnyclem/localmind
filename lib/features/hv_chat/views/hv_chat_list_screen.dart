import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/system_insets.dart';
import '../data/models/hv_conversation.dart';
import '../providers/hv_chat_providers.dart';
import 'components/hv_conversation_tile.dart';

/// Conversation list for `AppRoutes.hvChat` (T-M8-01). This is the parallel,
/// server-backed chat surface — unrelated to `lib/features/conversations`'
/// on-device chat history.
class HvChatListScreen extends ConsumerWidget {
  const HvChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final conversationsAsync = ref.watch(hvConversationsProvider);
    final systemBottomInset = bottomSystemInset(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: topPadding + 8,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0A0A0A)
                    : const Color(0xFFFAFAFA),
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
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedMenu01),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HyperVault Chat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) => conversations.isEmpty
                    ? _buildEmptyState(context, theme)
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(hvConversationsProvider.notifier)
                            .refresh(),
                        child: ListView.separated(
                          padding: EdgeInsets.only(
                            bottom: systemBottomInset + 96,
                          ),
                          itemCount: conversations.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isDark
                                ? const Color(0xFF1F1F1F)
                                : const Color(0xFFECECEC),
                          ),
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            return HvConversationTile(
                              conversation: conversation,
                              onTap: () => context.push(
                                AppRoutes.hvChatThread,
                                extra: conversation.id,
                              ),
                              onDelete: () =>
                                  _handleDelete(context, ref, conversation),
                            );
                          },
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          err is HyperVaultApiException
                              ? err.message
                              : 'Something went wrong loading your chats.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(hvConversationsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        PositionedDirectional(
          bottom: 24 + systemBottomInset,
          end: 24,
          child: FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.hvChatThread, extra: null),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
            label: const Text('New chat'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedBubbleChat,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No HyperVault chats yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat with any connected backend — your history lives '
              'on the server, so it follows you across devices.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    HvConversation conversation,
  ) async {
    try {
      await ref
          .read(hvConversationsProvider.notifier)
          .deleteConversation(conversation.id);
    } on HyperVaultApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete conversation.')),
        );
      }
    }
  }
}
