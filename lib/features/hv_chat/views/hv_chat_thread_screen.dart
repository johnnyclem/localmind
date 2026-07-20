import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/models/enums.dart';
import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/hv_error_toast.dart';
import '../../backends/data/models/backend.dart';
import '../../backends/providers/backends_providers.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../data/models/hv_chat_result.dart';
import '../data/models/hv_message.dart';
import '../data/on_device_chat_model.dart';
import '../providers/hv_chat_providers.dart';
import 'components/hv_backend_picker.dart';
import 'components/hv_message_bubble.dart';

/// A single thread for `AppRoutes.hvChatThread`. [conversationId] is `null`
/// for a brand-new, unsaved conversation (T-M8-02) — no API call happens
/// until the first send, at which point the returned `conversation_id` is
/// adopted locally (T-M8-10).
class HvChatThreadScreen extends ConsumerStatefulWidget {
  const HvChatThreadScreen({super.key, this.conversationId});

  final String? conversationId;

  @override
  ConsumerState<HvChatThreadScreen> createState() => _HvChatThreadScreenState();
}

class _HvChatThreadScreenState extends ConsumerState<HvChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String? _selectedBackendId;
  bool _useRecall = true;
  bool _useTools = true;

  Timer? _thinkingTimer;
  int _thinkingSeconds = 0;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _thinkingTimer?.cancel();
    super.dispose();
  }

  void _ensureBackendSelected(List<Backend> backends) {
    // The synthetic on-device entry lives outside `backends` (it's a Backend
    // list from `backendsProvider`, not a `Backend` itself) — never
    // auto-reassign away from a deliberate on-device selection.
    if (_selectedBackendId == HvBackendPicker.onDeviceBackendId) return;

    if (backends.isEmpty) {
      if (_selectedBackendId != null) {
        setState(() => _selectedBackendId = null);
      }
      return;
    }
    if (_selectedBackendId == null ||
        !backends.any((b) => b.id == _selectedBackendId)) {
      setState(() => _selectedBackendId = backends.first.id);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final threadAsync = ref.watch(hvThreadProvider(widget.conversationId));
    final backendsAsync = ref.watch(backendsProvider);
    final chatSettingsAsync = ref.watch(hvChatSettingsProvider);
    final capabilities = ref.watch(capabilitiesProvider).value;
    final onDeviceEngineState = ref.watch(onDeviceEngineProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final backends = backendsAsync.value?.backends ?? const <Backend>[];
    if (backendsAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureBackendSelected(backends);
      });
    }

    final threadState = threadAsync.value;
    final showDeepMemory = capabilities?.features.deepMemory ?? false;
    final maxChars = capabilities?.limits.chatMessageChars ?? 100000;
    final showOnDevice = capabilities?.features.onDeviceInference ?? false;
    final onDeviceReady =
        onDeviceEngineState.status == OnDeviceEngineStatus.loaded &&
        onDeviceEngineState.loadedModelId != null;

    return Column(
      children: [
        _buildHeader(context, theme, isDark, topPadding, threadState),
        Expanded(
          child: threadAsync.when(
            data: (state) => _buildMessages(theme, state),
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
                          : 'Could not load this conversation.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        hvThreadProvider(widget.conversationId),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (threadState?.isSending ?? false) _buildThinkingBanner(theme),
        SafeArea(
          top: false,
          child: _buildComposer(
            context,
            theme,
            backends,
            backendsAsync.isLoading,
            chatSettingsAsync.value,
            showDeepMemory,
            maxChars,
            threadState?.isSending ?? false,
            showOnDevice,
            onDeviceReady,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    double topPadding,
    HvThreadState? threadState,
  ) {
    final title = threadState?.title ?? 'New chat';
    final canShare = threadState?.conversationId != null;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: topPadding + 8,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.hvChat);
              }
            },
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShare08,
              color: canShare
                  ? null
                  : theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
            tooltip: 'Share',
            onPressed: canShare
                ? () => _openShareMenu(context, threadState!)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(ThemeData theme, HvThreadState state) {
    final messages = state.messages;
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAiBrain01,
                size: 72,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 20),
              Text(
                'Your whole AI life, one surface',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Pick a backend below and send your first message.',
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
    _scrollToBottom();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final HvMessage message = messages[index];
        return HvMessageBubble(
          message: message,
          onFeedback: message.isUser
              ? null
              : (feedback) => _handleFeedback(message.id, feedback),
        );
      },
    );
  }

  Widget _buildThinkingBanner(ThemeData theme) {
    final progress = (_thinkingSeconds / 120).clamp(0.0, 0.95);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thinking… ${_thinkingSeconds}s',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 3),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(
    BuildContext context,
    ThemeData theme,
    List<Backend> backends,
    bool backendsLoading,
    HvChatSettings? settings,
    bool showDeepMemory,
    int maxChars,
    bool isSending,
    bool showOnDevice,
    bool onDeviceReady,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final isOnDeviceSelected =
        _selectedBackendId == HvBackendPicker.onDeviceBackendId;
    final canSend =
        !isSending &&
        _selectedBackendId != null &&
        _textController.text.trim().isNotEmpty &&
        (!isOnDeviceSelected || onDeviceReady);
    final hasComposerTarget = backends.isNotEmpty || showOnDevice;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!backendsLoading && !hasComposerTarget)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Connect a backend first to start chatting.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.backends),
                    child: const Text('Connect'),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HvBackendPicker(
                backends: backends,
                selectedId: _selectedBackendId,
                showOnDevice: showOnDevice,
                onDeviceReady: onDeviceReady,
                onChanged: (value) {
                  if (value == HvBackendPicker.onDeviceBackendId &&
                      !onDeviceReady) {
                    context.push(AppRoutes.onDeviceModels);
                    return;
                  }
                  setState(() => _selectedBackendId = value);
                },
              ),
            ),
          Wrap(
            spacing: 4,
            children: [
              _ToggleChip(
                label: 'Recall',
                icon: HugeIcons.strokeRoundedDatabase01,
                active: _useRecall,
                onTap: () => setState(() => _useRecall = !_useRecall),
              ),
              _ToggleChip(
                label: 'Smart context',
                icon: HugeIcons.strokeRoundedMagicWand01,
                active: settings?.smartContext ?? false,
                onTap: () => ref
                    .read(hvChatSettingsProvider.notifier)
                    .setSmartContext(!(settings?.smartContext ?? false)),
              ),
              if (showDeepMemory)
                _ToggleChip(
                  label: 'Deep memory',
                  icon: HugeIcons.strokeRoundedBrain,
                  active: settings?.deepMemory ?? false,
                  onTap: () => ref
                      .read(hvChatSettingsProvider.notifier)
                      .setDeepMemory(!(settings?.deepMemory ?? false)),
                ),
              _ToggleChip(
                label: 'Tools',
                icon: HugeIcons.strokeRoundedAiIdea,
                active: _useTools,
                onTap: () => setState(() => _useTools = !_useTools),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 6,
                  maxLength: maxChars,
                  enabled: hasComposerTarget,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: !hasComposerTarget
                        ? 'Connect a backend to start chatting'
                        : isOnDeviceSelected
                        ? 'Message the on-device model…'
                        : 'Message ${backends.firstWhere((b) => b.id == _selectedBackendId, orElse: () => backends.first).name}…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: canSend ? _handleSend : null,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedSent02),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    final backendId = _selectedBackendId;
    if (text.isEmpty || backendId == null) return;

    final settings = ref.read(hvChatSettingsProvider).value;

    _thinkingTimer?.cancel();
    _thinkingSeconds = 0;
    _thinkingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _thinkingSeconds++);
    });

    try {
      final notifier = ref.read(
        hvThreadProvider(widget.conversationId).notifier,
      );
      if (backendId == HvBackendPicker.onDeviceBackendId) {
        await notifier.sendMessageOnDevice(
          text: text,
          useRecall: _useRecall,
          useSmartContext: settings?.smartContext,
          useDeepMemory: settings?.deepMemory,
        );
      } else {
        await notifier.sendMessage(
          text: text,
          backendId: backendId,
          useRecall: _useRecall,
          useSmartContext: settings?.smartContext,
          useDeepMemory: settings?.deepMemory,
          useTools: _useTools,
        );
      }
      _textController.clear();
      _scrollToBottom();
    } on NoOnDeviceModelLoadedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Set up an on-device model first.'),
            action: SnackBarAction(
              label: 'Local Models',
              onPressed: () => context.push(AppRoutes.onDeviceModels),
            ),
          ),
        );
      }
    } on HyperVaultApiException catch (e) {
      if (mounted) showHvError(context, e);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Check your connection.'),
          ),
        );
      }
    } finally {
      _thinkingTimer?.cancel();
      if (mounted) setState(() => _thinkingSeconds = 0);
    }
  }

  Future<void> _handleFeedback(String messageId, String? feedback) async {
    try {
      await ref
          .read(hvThreadProvider(widget.conversationId).notifier)
          .setFeedback(messageId, feedback);
    } on HyperVaultApiException catch (e) {
      if (mounted) showHvError(context, e);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update feedback.')),
        );
      }
    }
  }

  Future<void> _openShareMenu(
    BuildContext context,
    HvThreadState threadState,
  ) async {
    final appUrl = ref.read(capabilitiesProvider).value?.appUrl;
    String currentVisibility = threadState.visibility;
    String? currentShareSlug = threadState.shareSlug;
    String? lastShareUrl;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final resolvedShareUrl =
                lastShareUrl ??
                (currentShareSlug != null && appUrl != null
                    ? '$appUrl/c/$currentShareSlug'
                    : null);

            Future<void> selectVisibility(String value) async {
              if (value == currentVisibility) return;
              try {
                final url = await ref
                    .read(hvThreadProvider(widget.conversationId).notifier)
                    .updateVisibility(value);
                setSheetState(() {
                  currentVisibility = value;
                  lastShareUrl = url;
                  if (value == 'private') currentShareSlug = null;
                });
              } on HyperVaultApiException catch (e) {
                if (sheetContext.mounted) showHvError(sheetContext, e);
              } catch (e) {
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update visibility.'),
                    ),
                  );
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share conversation',
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    RadioGroup<String>(
                      groupValue: currentVisibility,
                      onChanged: (v) => selectVisibility(v!),
                      child: const Column(
                        children: [
                          RadioListTile<String>(
                            title: Text('Private'),
                            subtitle: Text('Only you can see this chat.'),
                            value: 'private',
                          ),
                          RadioListTile<String>(
                            title: Text('Shared — link only'),
                            subtitle: Text('Anyone with the link can view.'),
                            value: 'shared',
                          ),
                          RadioListTile<String>(
                            title: Text('Public'),
                            subtitle: Text('Listed and viewable by anyone.'),
                            value: 'public',
                          ),
                        ],
                      ),
                    ),
                    if (resolvedShareUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: resolvedShareUrl),
                            );
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(content: Text('Link copied')),
                            );
                          },
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCopy01,
                          ),
                          label: const Text('Copy link'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(16),
            color: active
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
