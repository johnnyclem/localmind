import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../providers/tts_providers.dart' as tts;

/// Mini TTS player bar shown when speech is playing or
/// initializing. Displays a waveform icon, a content preview, and a stop button.
class TtsPlayerBar extends ConsumerWidget {
  final EdgeInsetsGeometry margin;
  
  const TtsPlayerBar({
    super.key, 
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ttsState = ref.watch(tts.ttsProvider);
    ref.listen(tts.ttsProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!ttsState.isSpeaking && !ttsState.isInitializing) {
      return const SizedBox.shrink();
    }

    final preview = _truncateContent(ttsState.playingContent);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          children: [
            _AnimatedWaveIndicator(isActive: ttsState.isSpeaking),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preview ??
                        (ttsState.isInitializing ? l10n.loading : 'Playing'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ttsState.isInitializing)
                    Text(
                      l10n.initializing,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref.read(tts.ttsProvider.notifier).stop(),
              child: Tooltip(
                message: l10n.stop,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.stop_circle,
                    size: 20,
                    color: isDark ? Colors.red[300] : Colors.red[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _truncateContent(String? content) {
    if (content == null || content.isEmpty) return null;
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }
}

/// An animated audio wave indicator with a subtle bounce effect.
class _AnimatedWaveIndicator extends StatefulWidget {
  final bool isActive;
  const _AnimatedWaveIndicator({required this.isActive});

  @override
  State<_AnimatedWaveIndicator> createState() => _AnimatedWaveIndicatorState();
}

class _AnimatedWaveIndicatorState extends State<_AnimatedWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isActive ? 1.0 + _controller.value * 0.15 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Icon(
            Icons.graphic_eq,
            size: 18,
            color: widget.isActive ? const Color(0xFF3B82F6) : Colors.grey,
          ),
        );
      },
    );
  }
}
