import 'dart:async';
import 'package:flutter/material.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/theme/colors.dart';
import 'package:localmind/features/chat/data/models/message.dart';
import 'package:localmind/features/chat/views/components/processing_indicator.dart';
import 'package:localmind/features/chat/views/components/typing_indicator.dart';
import 'package:localmind/features/chat/views/components/reasoning_widget.dart';
import 'package:localmind/features/chat/views/components/message_action_bar.dart';
import 'markdown/themed_gpt_markdown.dart';
import 'tool_bubble/tool_timeline.dart';

class AssistantBubble extends StatelessWidget {
  const AssistantBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onRetry,
    this.onDelete,
    this.isStreaming = false,
  });

  final Message message;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.reasoningContent != null &&
              message.reasoningContent!.isNotEmpty)
            ReasoningWidget(
              reasoningContent: message.reasoningContent,
              isStreaming: isStreaming,
            ),
          if (isStreaming && message.content.isEmpty && message.isProcessing)
            const ProcessingIndicator()
          else if (isStreaming && message.content.isEmpty)
            const TypingIndicator()
          else if (isStreaming)
            _StreamingContent(content: message.content, isDark: isDark)
          else
            MarkdownContent(content: message.content, isDark: isDark),
          if (message.status == MessageStatus.error &&
              message.errorMessage != null &&
              message.errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  message.errorMessage!,
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (message.toolEvents != null && message.toolEvents!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ToolTimeline(events: message.toolEvents!),
            ),
          if (isStreaming && message.content.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: _StreamingIndicator(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkMutedText
                      : AppColors.lightMutedText,
                ),
              ),
              if (message.status == MessageStatus.error) ...[
                const SizedBox(width: 4),
                Icon(Icons.error_outline, size: 14, color: Colors.red[400]),
              ],
              const Spacer(),
              if (!isStreaming &&
                  (message.status == MessageStatus.complete ||
                      message.status == MessageStatus.error ||
                      message.status == MessageStatus.cancelled))
                MessageActionBar(
                  content: message.content,
                  onCopy: onCopy,
                  onRetry: onRetry,
                  onDelete: onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreamingContent extends StatefulWidget {
  const _StreamingContent({required this.content, required this.isDark});

  final String content;
  final bool isDark;

  @override
  State<_StreamingContent> createState() => _StreamingContentState();
}

class _StreamingContentState extends State<_StreamingContent> {
  static const Duration _updateInterval = Duration(milliseconds: 80);
  Timer? _flushTimer;
  String _visibleContent = '';

  @override
  void initState() {
    super.initState();
    _visibleContent = widget.content;
  }

  @override
  void didUpdateWidget(covariant _StreamingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content == widget.content) {
      return;
    }

    if (widget.content.length < _visibleContent.length) {
      _flushTimer?.cancel();
      _visibleContent = widget.content;
      return;
    }

    _flushTimer ??= Timer(_updateInterval, () {
      _flushTimer = null;
      if (mounted) {
        setState(() {
          _visibleContent = widget.content;
        });
      }
    });
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBodyContent(content: _visibleContent, isDark: widget.isDark);
  }
}

class _StreamingIndicator extends StatefulWidget {
  const _StreamingIndicator();

  @override
  State<_StreamingIndicator> createState() => _StreamingIndicatorState();
}

class _StreamingIndicatorState extends State<_StreamingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat();

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDark
        ? AppColors.darkMutedText
        : AppColors.lightMutedText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(right: index == 2 ? 0 : 4),
              child: Transform.translate(
                offset: Offset(0, -2.5 * _animations[index].value),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(
                      alpha: 0.35 + 0.65 * _animations[index].value,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
