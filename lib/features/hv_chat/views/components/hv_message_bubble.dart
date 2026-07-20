import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../tts/providers/tts_providers.dart' as tts;
import '../../data/models/hv_message.dart';

/// Renders one turn: user bubbles right-aligned (primary), assistant
/// left-aligned (bordered/neutral) — T-M8-04. Plain selectable text, no
/// markdown renderer (v1 scope). Assistant footers surface `truncated`,
/// `recalled_memories`, `deep_memory` labels, the `model` tag, a simple
/// tools-turn badge, and thumbs up/down (T-M8-12).
class HvMessageBubble extends StatelessWidget {
  const HvMessageBubble({super.key, required this.message, this.onFeedback});

  final HvMessage message;
  final void Function(String? feedback)? onFeedback;

  bool get _isPersisted =>
      message.id.isNotEmpty && !message.id.startsWith('local-');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.isUser;

    final bubbleColor = isUser
        ? theme.colorScheme.primary
        : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F1F1));
    final textColor = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final captionColor = textColor.withValues(alpha: 0.65);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              message.content.isEmpty ? ' ' : message.content,
              style: TextStyle(color: textColor, height: 1.35),
            ),
            if (message.truncated)
              _Caption(
                'Backend stopped at its length limit — say "continue".',
                color: captionColor,
              ),
            if (message.recalledMemories?.isNotEmpty ?? false)
              _Caption(
                'Grounded in your memories: ${message.recalledMemories!.join(', ')}',
                color: captionColor,
              ),
            if (message.deepMemoryLabels?.isNotEmpty ?? false)
              _Caption(
                'From your conversation graph: ${message.deepMemoryLabels!.join(', ')}',
                color: captionColor,
              ),
            if (message.tools != null && message.tools!.turnCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: captionColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Tools · ${message.tools!.turnCount}',
                        style: TextStyle(fontSize: 11, color: captionColor),
                      ),
                    ),
                    if (message.tools!.isStale)
                      Text(
                        'Recompile your toolkit under Tools',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            if (!isUser && (message.model?.isNotEmpty ?? false))
              _Caption(message.model!, color: captionColor),
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TtsButton(message: message, color: textColor),
                    if (onFeedback != null) ...[
                      _FeedbackButton(
                        icon: HugeIcons.strokeRoundedThumbsUp,
                        active: message.feedback == 'up',
                        color: textColor,
                        enabled: _isPersisted,
                        onPressed: () =>
                            onFeedback!(message.feedback == 'up' ? null : 'up'),
                      ),
                      _FeedbackButton(
                        icon: HugeIcons.strokeRoundedThumbsDown,
                        active: message.feedback == 'down',
                        color: textColor,
                        enabled: _isPersisted,
                        onPressed: () => onFeedback!(
                          message.feedback == 'down' ? null : 'down',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

/// Read-aloud button for assistant bubbles (M14 T-hv-tts). Reuses the
/// app-wide [tts.ttsProvider] shared with the existing `chat` feature's
/// speaker button (`message_action_bar.dart`) so starting playback here
/// stops any other message currently speaking, and playback survives
/// navigation via the global mini-player mounted in the sidebar shell.
class _TtsButton extends ConsumerWidget {
  const _TtsButton({required this.message, required this.color});

  final HvMessage message;
  final Color color;

  bool _isThisActive(tts.TtsState state) {
    if (message.id.isEmpty) return false;
    return state.playingMessageId == message.id &&
        (state.isSpeaking || state.isPaused);
  }

  Future<void> _toggle(WidgetRef ref, bool isActive) async {
    final notifier = ref.read(tts.ttsProvider.notifier);
    if (isActive) {
      await notifier.stop();
      return;
    }
    final state = ref.read(tts.ttsProvider);
    if (state.isSpeaking || state.isPaused) {
      await notifier.stop();
    }
    try {
      await notifier.speak(message.content, messageId: message.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(tts.ttsProvider);
    final isActive = _isThisActive(state);
    final isBusy = isActive && state.isInitializing;

    final String label = isBusy
        ? 'Generating audio…'
        : (isActive ? 'Stop reading' : 'Read aloud');

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: IconButton(
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          icon: isBusy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color.withValues(alpha: 0.55),
                  ),
                )
              : HugeIcon(
                  icon: isActive
                      ? HugeIcons.strokeRoundedStopCircle
                      : HugeIcons.strokeRoundedVolumeUp,
                  size: 16,
                  color: isActive
                      ? theme.colorScheme.primary
                      : color.withValues(alpha: 0.55),
                ),
          onPressed: isBusy ? null : () => _toggle(ref, isActive),
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.active,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final List<List<dynamic>> icon;
  final bool active;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      icon: HugeIcon(
        icon: icon,
        size: 16,
        color: active
            ? theme.colorScheme.primary
            : color.withValues(alpha: 0.55),
      ),
      onPressed: enabled ? onPressed : null,
    );
  }
}
