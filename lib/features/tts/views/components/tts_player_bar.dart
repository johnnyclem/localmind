import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../providers/tts_providers.dart' as tts;

class TtsPlayerBar extends ConsumerWidget {
  final EdgeInsetsGeometry margin;

  const TtsPlayerBar({
    super.key,
    this.margin = const EdgeInsets.only(left: 16, right: 16, bottom: 8),
  });

  String? _truncateContent(String? content) {
    if (content == null || content.isEmpty) return null;
    if (content.length <= 50) return content;
    return '${content.substring(0, 47)}...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ttsState = ref.watch(tts.ttsProvider);
    final notifier = ref.read(tts.ttsProvider.notifier);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<tts.TtsState>(tts.ttsProvider, (prev, next) {
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

    if ((!ttsState.isSpeaking && !ttsState.isInitializing) || ttsState.isPreview) {
      return const SizedBox.shrink();
    }

    final preview = _truncateContent(ttsState.playingContent);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => notifier.togglePauseResume(),
                  child: Tooltip(
                    message: ttsState.isPaused ? l10n.resume : l10n.pause,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        ttsState.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        preview ??
                            (ttsState.isInitializing
                                ? l10n.loading
                                : 'Playing'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ttsState.isInitializing)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            l10n.initializing,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      if (!ttsState.isInitializing)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              backgroundColor: theme.colorScheme.secondary,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                              minHeight: 3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                  const SizedBox(width: 12),
                  if (!ttsState.isInitializing)
                    _WaveformIndicator(isPlaying: !ttsState.isPaused),
                  const SizedBox(width: 12),
              GestureDetector(
                onTap: () => notifier.stop(),
                child: Tooltip(
                  message: l10n.stop,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.stop_rounded,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}

class _WaveformIndicator extends StatefulWidget {
  final bool isPlaying;

  const _WaveformIndicator({required this.isPlaying});

  @override
  State<_WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<_WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _WaveformIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = theme.colorScheme.primary;

    return Container(
      height: 16,
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          
          final h1 = widget.isPlaying 
              ? 4.0 + 12.0 * (0.5 + 0.5 * math.sin(t * 2 * math.pi))
              : 4.0;
          final h2 = widget.isPlaying 
              ? 4.0 + 12.0 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + math.pi / 3))
              : 6.0;
          final h3 = widget.isPlaying 
              ? 4.0 + 12.0 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + 2 * math.pi / 3))
              : 4.0;

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(h1, barColor),
              const SizedBox(width: 2),
              _buildBar(h2, barColor),
              const SizedBox(width: 2),
              _buildBar(h3, barColor),
            ],
          );
        },
      ),
    );
  }
}
