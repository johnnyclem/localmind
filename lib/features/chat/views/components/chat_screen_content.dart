import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:localmind/core/theme/colors.dart';
import 'package:localmind/core/components/model_picker/model_picker_sheet.dart';
import 'package:localmind/core/components/server/server_icon_picker.dart';
import 'package:localmind/core/components/tts/tts_player_bar.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/models/model_info.dart';
import 'package:localmind/core/providers/app_providers.dart';
import 'package:localmind/core/providers/conversation_providers.dart' as conv;
import 'package:localmind/core/providers/personas_providers.dart';
import 'package:localmind/core/providers/server_providers.dart';
import 'package:localmind/core/routes/app_routes.dart';
import 'package:localmind/core/utils/system_insets.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:localmind/features/conversations/data/models/conversation.dart';
import 'package:localmind/features/personas/data/models/persona.dart';
import 'package:localmind/features/servers/data/models/server.dart';
import '../../data/models/message.dart';
import '../../providers/chat_mcp_providers.dart';
import '../../providers/chat_providers.dart';
import 'chat_auto_scroll_controller.dart';
import 'chat_input_bar.dart';
import 'chat_settings_sheet.dart';
import 'edit_message_dialog.dart';
import 'notification_permission_banner.dart';
import 'message_list/message_list.dart';
import 'message_list/empty_state.dart';
import 'message_list/corrupted_state.dart';
import 'top_bar/model_top_bar.dart';
import 'top_bar/connection_banner.dart';
import 'top_bar/persona_indicator.dart';
import 'top_bar/smart_reply_chips.dart';

class ChatScreenContent extends ConsumerStatefulWidget {
  const ChatScreenContent({super.key});

  @override
  ConsumerState<ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends ConsumerState<ChatScreenContent>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isApprovalDialogOpen = false;
  late final ChatAutoScrollController _autoScroll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inputFocusNode.addListener(() => setState(() {}));
    _scrollController.addListener(
      () => _autoScroll.onScrollChanged(_scrollController),
    );
    _autoScroll = ChatAutoScrollController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref.read(chatProvider.notifier).checkpointStreamingMessage(flush: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoSelectFirstLoadedModelProvider);

    ref.listen<PendingToolApproval?>(
      chatProvider.select((s) => s.pendingToolApproval),
      (previous, next) {
        if (next != null && !_isApprovalDialogOpen) {
          _showToolApprovalDialog(context, next);
        }
      },
    );

    return _ChatBody(
      scrollController: _scrollController,
      inputFocusNode: _inputFocusNode,
      autoScroll: _autoScroll,
      onModelPicker: () => _showModelPicker(context),
      onMenuAction: (action) => _handleMenuAction(action, context),
    );
  }

  void _showModelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const ModelPickerSheet(),
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'new_chat':
        ref.read(chatProvider.notifier).startNewConversation();
      case 'persona':
        _showPersonaPicker(context);
      case 'remove_persona':
        final activeConv = ref.read(conv.activeConversationProvider);
        if (activeConv != null) {
          ref
              .read(conv.conversationsProvider.notifier)
              .updatePersona(activeConv.id, null, null);
        }
      case 'clear':
        showDialog(
          context: context,
          builder: (context) {
            final dlgL10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(dlgL10n.clear_conversation_title),
              content: Text(dlgL10n.clear_conversation_body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(dlgL10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(chatProvider.notifier).clearConversation();
                  },
                  child: Text(dlgL10n.clear),
                ),
              ],
            );
          },
        );
    }
  }

  void _showPersonaPicker(BuildContext context) {
    final personasAsync = ref.read(personasNotifierProvider);
    final personas = personasAsync.value ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeConv = ref.read(conv.activeConversationProvider);
    final currentPersonaId = activeConv?.personaId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final sheetL10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  sheetL10n.select_persona,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: personas.length,
                    itemBuilder: (context, index) {
                      final p = personas[index];
                      final isSelected = p.id == currentPersonaId;
                      final accent = isDark
                          ? AppColors.darkAccent
                          : AppColors.lightAccent;
                      return ListTile(
                        leading: Text(
                          p.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: p.description != null
                            ? Text(
                                p.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkMutedText
                                      : AppColors.lightMutedText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: accent)
                            : null,
                        onTap: () {
                          if (activeConv != null) {
                            ref
                                .read(conv.conversationsProvider.notifier)
                                .updatePersona(
                                  activeConv.id,
                                  p.id,
                                  p.systemPrompt,
                                );
                          }
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showToolApprovalDialog(
    BuildContext context,
    PendingToolApproval approval,
  ) {
    setState(() => _isApprovalDialogOpen = true);
    final l10n = AppLocalizations.of(context)!;

    showShadDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShadDialog.alert(
        title: Text('${l10n.execute_tool_title}: ${approval.toolCall.name}?'),
        description: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.execute_tool_request_desc),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  const JsonEncoder.withIndent(
                    '  ',
                  ).convert(approval.toolCall.arguments),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ShadButton.outline(
            child: Text(l10n.reject),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton(
            child: Text(l10n.approve),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ).then((value) {
      if (mounted) setState(() => _isApprovalDialogOpen = false);
      ref.read(chatProvider.notifier).approveTool(value ?? false);
    });
  }
}

class _ChatBody extends ConsumerWidget {
  const _ChatBody({
    required this.scrollController,
    required this.inputFocusNode,
    required this.autoScroll,
    required this.onModelPicker,
    required this.onMenuAction,
  });

  final ScrollController scrollController;
  final FocusNode inputFocusNode;
  final ChatAutoScrollController autoScroll;
  final VoidCallback onModelPicker;
  final void Function(String) onMenuAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = ref.watch(chatProvider.select((s) => s.isLoading));
    final messages = ref.watch(chatProvider.select((s) => s.messages));
    final isStreaming = ref.watch(chatProvider.select((s) => s.isStreaming));
    final streamingLength = ref.watch(
      chatProvider.select((s) => s.streamingMessage?.content.length ?? 0),
    );
    final errorMessage = ref.watch(chatProvider.select((s) => s.errorMessage));
    final selectedModel = ref.watch(selectedModelProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final activeServer = ref.watch(activeServerProvider);
    final activeConversation = ref.watch(conv.activeConversationProvider);
    final personaId = activeConversation?.personaId;
    final persona = personaId != null
        ? ref.watch(personaByIdProvider(personaId))
        : null;
    final keyboardBottomInset = bottomKeyboardInset(context);
    final systemBottomInset = bottomSystemInset(context);
    final effectiveBottomInset = keyboardBottomInset > 0
        ? 0.0
        : systemBottomInset;

    final needsScroll = autoScroll.checkAndUpdate(
      messageCount: messages.length,
      streamingLength: streamingLength,
      isStreaming: isStreaming,
    );
    if (needsScroll) {
      autoScroll.scheduleAutoScroll(
        controller: scrollController,
        streaming: isStreaming,
      );
    }

    return Column(
      children: [
        ModelTopBar(selectedModel: selectedModel, onTap: onModelPicker),
        _ScreenAppBar(
          activeServer: activeServer,
          connectionStatus: connectionStatus,
          isDark: isDark,
          persona: persona,
          onMenuAction: onMenuAction,
          onPersonaPicker: () => _openPersonaPicker(context, ref),
        ),
        const NotificationPermissionBanner(),
        if (connectionStatus == ConnectionStatus.disconnected ||
            connectionStatus == ConnectionStatus.error)
          ConnectionBanner(status: connectionStatus),
        if (persona != null)
          PersonaIndicator(
            persona: persona,
            onTap: () => _openPersonaPicker(context, ref),
            onRemove: () {
              final activeConv = ref.read(conv.activeConversationProvider);
              if (activeConv != null) {
                ref
                    .read(conv.conversationsProvider.notifier)
                    .updatePersona(activeConv.id, null, null);
              }
            },
          ),
        const TtsPlayerBar(),
        Expanded(
          child: Stack(
            children: [
              _MessageArea(
                isLoading: isLoading,
                messages: messages,
                activeConversation: activeConversation,
                errorMessage: errorMessage,
                selectedModel: selectedModel,
                isStreaming: isStreaming,
                scrollController: scrollController,
                effectiveBottomInset: effectiveBottomInset,
                keyboardBottomInset: keyboardBottomInset,
                onModelPicker: onModelPicker,
              ),
              _ChatBottomBar(
                isStreaming: isStreaming,
                keyboardBottomInset: keyboardBottomInset,
                inputFocusNode: inputFocusNode,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _openPersonaPicker(BuildContext context, WidgetRef ref) {
  final personasAsync = ref.read(personasNotifierProvider);
  final personas = personasAsync.value ?? [];
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final activeConv = ref.read(conv.activeConversationProvider);
  final currentPersonaId = activeConv?.personaId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final sheetL10n = AppLocalizations.of(context)!;
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                sheetL10n.select_persona,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: personas.length,
                  itemBuilder: (context, index) {
                    final p = personas[index];
                    final isSelected = p.id == currentPersonaId;
                    final accent = isDark
                        ? AppColors.darkAccent
                        : AppColors.lightAccent;
                    return ListTile(
                      leading: Text(
                        p.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: p.description != null
                          ? Text(
                              p.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkMutedText
                                    : AppColors.lightMutedText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: accent)
                          : null,
                      onTap: () {
                        if (activeConv != null) {
                          ref
                              .read(conv.conversationsProvider.notifier)
                              .updatePersona(
                                activeConv.id,
                                p.id,
                                p.systemPrompt,
                              );
                        }
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).then((_) {});
}

class _MessageArea extends ConsumerWidget {
  const _MessageArea({
    required this.isLoading,
    required this.messages,
    required this.activeConversation,
    this.errorMessage,
    required this.selectedModel,
    required this.isStreaming,
    required this.scrollController,
    required this.effectiveBottomInset,
    required this.keyboardBottomInset,
    required this.onModelPicker,
  });

  final bool isLoading;
  final List<Message> messages;
  final Conversation? activeConversation;
  final String? errorMessage;
  final ModelInfo? selectedModel;
  final bool isStreaming;
  final ScrollController scrollController;
  final double effectiveBottomInset;
  final double keyboardBottomInset;
  final VoidCallback onModelPicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (messages.isEmpty && activeConversation != null) {
      return CorruptedChatState(
        conversation: activeConversation!,
        errorMessage: errorMessage,
        onStartNewChat: () =>
            ref.read(chatProvider.notifier).startNewConversation(),
      );
    }

    if (messages.isEmpty) {
      return EmptyState(
        onQuickPrompt: (prompt) =>
            ref.read(chatProvider.notifier).sendMessage(prompt),
        quickPrompts: [
          l10n.quick_write,
          l10n.quick_explain,
          l10n.quick_debug,
          l10n.quick_async,
        ],
        recentConversations: ref.watch(conv.recentConversationsProvider),
        onSeeAll: () => context.push(AppRoutes.chatHistory),
        selectedModel: selectedModel,
        onModelTap: onModelPicker,
        selectedPersona: ref.watch(selectedPersonaProvider),
        onPersonaTap: () => _openPersonaPickerForPreselection(context, ref),
      );
    }

    return MessageList(
      scrollController: scrollController,
      messages: messages,
      isStreaming: isStreaming,
      onRetry: (messageId) =>
          ref.read(chatProvider.notifier).retryMessage(messageId),
      onDelete: (messageId) =>
          ref.read(chatProvider.notifier).deleteMessage(messageId),
      onEdit: (messageId, currentContent) async {
        final newContent = await EditMessageDialog.show(
          context,
          initialContent: currentContent,
        );
        if (newContent != null && newContent != currentContent) {
          await ref
              .read(chatProvider.notifier)
              .editMessage(messageId, newContent);
        }
      },
      hasSmartReplies:
          !isStreaming &&
          keyboardBottomInset == 0 &&
          (ref.watch(smartRepliesProvider).asData?.value.isNotEmpty ?? false),
      bottomInset: effectiveBottomInset,
    );
  }
}

void _openPersonaPickerForPreselection(BuildContext context, WidgetRef ref) {
  final personasAsync = ref.read(personasNotifierProvider);
  final personas = personasAsync.value ?? [];
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final currentPersona = ref.watch(selectedPersonaProvider);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final sheetL10n = AppLocalizations.of(context)!;
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                sheetL10n.select_persona,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: personas.length,
                  itemBuilder: (context, index) {
                    final p = personas[index];
                    final isSelected = p.id == currentPersona?.id;
                    final accent = isDark
                        ? AppColors.darkAccent
                        : AppColors.lightAccent;
                    return ListTile(
                      leading: Text(
                        p.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: p.description != null
                          ? Text(
                              p.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkMutedText
                                    : AppColors.lightMutedText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: accent)
                          : null,
                      onTap: () {
                        ref.read(selectedPersonaProvider.notifier).select(p);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).then((_) {});
}

class _ScreenAppBar extends ConsumerWidget {
  const _ScreenAppBar({
    required this.activeServer,
    required this.connectionStatus,
    required this.isDark,
    required this.persona,
    required this.onMenuAction,
    required this.onPersonaPicker,
  });

  final Server? activeServer;
  final ConnectionStatus connectionStatus;
  final bool isDark;
  final Persona? persona;
  final void Function(String) onMenuAction;
  final VoidCallback onPersonaPicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final mcpConfig = ref.watch(chatMcpConfigProvider);
    final isMcpEnabled = settings.mcpEnabled && mcpConfig.enabled;

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
            child: Row(
              children: [
                if (activeServer != null) ...[
                  _buildServerIcon(context, activeServer),
                  const SizedBox(width: 8),
                ],
                Text(
                  activeServer?.name ?? l10n.chat_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connectionStatus == ConnectionStatus.connected
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
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
              PopupMenuItem(
                value: 'persona',
                child: ListTile(
                  leading: Icon(
                    persona != null
                        ? Icons.swap_horiz
                        : Icons.smart_toy_outlined,
                  ),
                  title: Text(
                    persona != null ? l10n.change_persona : l10n.set_persona,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (persona != null)
                PopupMenuItem(
                  value: 'remove_persona',
                  child: ListTile(
                    leading: const Icon(Icons.person_remove_outlined),
                    title: Text(l10n.remove_persona),
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
}

Widget _buildServerIcon(BuildContext context, Server? server) {
  if (server == null) return const SizedBox.shrink();

  final iconData = server.iconName != null
      ? getHugeIconByName(server.iconName)
      : getDefaultServerIcon(server.type.name);

  if (iconData == null) return const Icon(Icons.dns, size: 18);

  return HugeIcon(
    icon: iconData.icon,
    size: 18,
    color: Theme.of(context).colorScheme.primary,
  );
}

class _ChatBottomBar extends ConsumerWidget {
  const _ChatBottomBar({
    required this.isStreaming,
    required this.keyboardBottomInset,
    required this.inputFocusNode,
  });

  final bool isStreaming;
  final double keyboardBottomInset;
  final FocusNode inputFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isStreaming && keyboardBottomInset == 0) ...[
              const SizedBox(height: 4),
              _SmartReplyChipsWrapper(),
            ],
            ChatInputBar(
              focusNode: inputFocusNode,
              isStreaming: isStreaming,
              onSend: (message, {attachments}) {
                ref
                    .read(chatProvider.notifier)
                    .sendMessage(message, attachments: attachments);
              },
              onStop: () => ref.read(chatProvider.notifier).cancelStream(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartReplyChipsWrapper extends ConsumerWidget {
  const _SmartReplyChipsWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SmartReplyChips(
      onSend: (message) {
        ref.read(chatProvider.notifier).sendMessage(message);
      },
    );
  }
}
