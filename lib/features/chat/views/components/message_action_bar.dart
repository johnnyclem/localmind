import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../../tts/providers/tts_providers.dart' as tts;

class MessageActionBar extends ConsumerStatefulWidget {
  const MessageActionBar({
    super.key,
    required this.content,
    this.onCopy,
    this.onRetry,
    this.onDelete,
    this.onEdit,
    this.onShare,
  });

  final String content;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  @override
  ConsumerState<MessageActionBar> createState() => _MessageActionBarState();
}

class _MessageActionBarState extends ConsumerState<MessageActionBar> {

  void _toggleTts() async {
    final ttsNotifier = ref.read(tts.ttsProvider.notifier);
    final ttsState = ref.read(tts.ttsProvider);
    final isThisPlaying = ttsState.playingContent == widget.content && ttsState.isSpeaking;

    if (isThisPlaying) {
      await ttsNotifier.stop();
    } else {
      if (ttsState.isSpeaking) {
        await ttsNotifier.stop();
      }
      try {
        await ttsNotifier.speak(widget.content);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ttsState = ref.watch(tts.ttsProvider);
    final isThisPlaying = ttsState.playingContent == widget.content && ttsState.isSpeaking;
    final isThisInitializing = ttsState.playingContent == widget.content && ttsState.isInitializing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.copy,
          label: l10n.copy,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.content));
            widget.onCopy?.call();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.copied_to_clipboard),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
        if (widget.onRetry != null) ...[
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.refresh,
            label: l10n.retry,
            onTap: widget.onRetry,
          ),
        ],
        if (widget.onEdit != null) ...[
          const SizedBox(width: 4),
          _ActionButton(icon: Icons.edit, label: l10n.edit, onTap: widget.onEdit),
        ],
        if (widget.onDelete != null) ...[
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.delete_outline,
            label: l10n.delete,
            onTap: () => _showDeleteConfirmation(context),
            isDestructive: true,
          ),
        ],
        if (widget.onShare != null) ...[
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.ios_share,
            label: l10n.share,
            onTap: widget.onShare,
          ),
        ],
        const SizedBox(width: 4),
        _ActionButton(
          icon: isThisPlaying
              ? Icons.stop_circle
              : (isThisInitializing ? Icons.hourglass_top : Icons.volume_up),
          label: isThisPlaying
              ? l10n.stop
              : (isThisInitializing ? l10n.initializing : l10n.read_aloud),
          onTap: isThisInitializing ? null : _toggleTts,
        ),
        const SizedBox(width: 4),
        _ActionButton(
          icon: Icons.more_horiz,
          label: l10n.more,
          onTap: () => _showMoreOptions(context),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final dlgL10n = AppLocalizations.of(context)!;
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(dlgL10n.delete_message_title),
        description: Text(dlgL10n.cannot_undo),
        actions: [
          ShadButton(
            child: Text(dlgL10n.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ShadButton(
            child: Text(dlgL10n.delete),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    final sheetL10n = AppLocalizations.of(context)!;
    final ttsState = ref.read(tts.ttsProvider);
    final isThisPlaying = ttsState.playingContent == widget.content && ttsState.isSpeaking;

    showShadSheet(
      context: context,
      builder: (context) => ShadSheet(
        title: Text(sheetL10n.message_options),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(sheetL10n.copy_markdown),
              onTap: () {
                Navigator.of(context).pop();
                Clipboard.setData(ClipboardData(text: widget.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(sheetL10n.copied_markdown)),
                );
              },
            ),
            ListTile(
              leading: Icon(isThisPlaying ? Icons.stop : Icons.volume_up),
              title: Text(isThisPlaying ? sheetL10n.stop_reading : sheetL10n.read_aloud),
              onTap: () {
                Navigator.of(context).pop();
                _toggleTts();
              },
            ),
            if (widget.onShare != null)
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(sheetL10n.share),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onShare?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text(sheetL10n.character_count(widget.content.length)),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = widget.isDestructive
        ? (isDark ? Colors.red[300] : Colors.red[600])
        : (isDark ? const Color(0xFF888888) : const Color(0xFF666666));

    final hoverColor = widget.isDestructive
        ? (isDark ? Colors.red[200] : Colors.red[500])
        : (isDark ? const Color(0xFFAAAAAA) : const Color(0xFF444444));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
          onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
          onTapCancel: widget.onTap != null
              ? () => _controller.reverse()
              : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _scaleAnimation.value,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _isHovered
                    ? (isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE5E5E5))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: _isHovered ? hoverColor : baseColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
