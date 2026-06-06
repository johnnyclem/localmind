import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../../../core/models/enums.dart';
import '../../data/models/message.dart';
import 'message_action_bar.dart';
import 'processing_indicator.dart';
import 'typing_indicator.dart';
import 'audio_player_widget.dart';
import 'reasoning_widget.dart';
import '../../data/tools/tool_definition.dart';
import '../../data/tools/tool_event.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onRetry,
    this.onDelete,
    this.onEdit,
    this.isStreaming = false,
  });

  final Message message;
  final VoidCallback? onCopy;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: _buildBubble(context));
  }

  Widget _buildBubble(BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return _AnimatedBubble(
          alignment: AlignmentDirectional.centerEnd,
          child: _UserBubble(
            message: message,
            onCopy: onCopy,
            onDelete: onDelete,
            onEdit: onEdit,
          ),
        );
      case MessageRole.assistant:
        return _AnimatedBubble(
          alignment: AlignmentDirectional.centerStart,
          child: _AssistantBubble(
            message: message,
            onCopy: onCopy,
            onRetry: onRetry,
            onDelete: onDelete,
            isStreaming: isStreaming,
          ),
        );
      case MessageRole.system:
        return _AnimatedBubble(
          alignment: AlignmentDirectional.center,
          child: _SystemBubble(message: message),
        );
      case MessageRole.tool:
        return _AnimatedBubble(
          alignment: AlignmentDirectional.centerStart,
          child: _ToolBubble(message: message),
        );
    }
  }
}

class _AnimatedBubble extends StatelessWidget {
  const _AnimatedBubble({required this.child, required this.alignment});

  final Widget child;
  final AlignmentDirectional alignment;

  @override
  Widget build(BuildContext context) {
    final resolvedAlignment = alignment.resolve(Directionality.of(context));
    final offset = resolvedAlignment == Alignment.centerRight
        ? const Offset(0.15, 0.0)
        : resolvedAlignment == Alignment.centerLeft
        ? const Offset(-0.15, 0.0)
        : const Offset(0.0, 0.1);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - value) * 50,
              offset.dy * (1 - value) * 30,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({
    required this.message,
    this.onCopy,
    this.onDelete,
    this.onEdit,
  });

  final Message message;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsetsDirectional.only(
              start: 48,
              end: 8,
              top: 4,
              bottom: 2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(18),
                topEnd: Radius.circular(18),
                bottomStart: Radius.circular(18),
                bottomEnd: const Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.attachmentPaths != null &&
                    message.attachmentPaths!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AttachmentList(
                      paths: message.attachmentPaths!,
                      isUser: true,
                    ),
                  ),
                SelectionArea(
                  child: _ThemedGptMarkdown(
                    content: message.content,
                    isDark: isDark,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF666666)
                        : const Color(0xFF999999),
                  ),
                ),
                if (message.status == MessageStatus.error) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.error_outline, size: 14, color: Colors.red[200]),
                ],
                const SizedBox(width: 8),
                MessageActionBar(
                  content: message.content,
                  onCopy: onCopy,
                  onDelete: onDelete,
                  onEdit: onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({
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
            _MarkdownContent(content: message.content, isDark: isDark),
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
              child: _ToolTimeline(events: message.toolEvents!),
            ),
          if (isStreaming && message.content.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: StreamingIndicator(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF666666)
                      : const Color(0xFF999999),
                ),
              ),
              if (message.status == MessageStatus.error) ...[
                const SizedBox(width: 4),
                Icon(Icons.error_outline, size: 14, color: Colors.red[400]),
              ],
              const Spacer(),
              if (!isStreaming &&
                  (message.status == MessageStatus.complete ||
                      message.status == MessageStatus.error))
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

class _StreamingTextContent extends StatelessWidget {
  const _StreamingTextContent({required this.content, required this.isDark});

  final String content;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 15,
        height: 1.5,
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
    return _MarkdownBodyContent(
      content: _visibleContent,
      isDark: widget.isDark,
    );
  }
}

class _MarkdownContent extends StatelessWidget {
  const _MarkdownContent({required this.content, required this.isDark});

  final String content;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (content.length > 2000) {
      return _DeferredMarkdownContent(content: content, isDark: isDark);
    }

    return _MarkdownBodyContent(content: content, isDark: isDark);
  }
}

class _MarkdownBodyContent extends StatelessWidget {
  const _MarkdownBodyContent({required this.content, required this.isDark});

  final String content;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: _ThemedGptMarkdown(
        content: content,
        isDark: isDark,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ThemedGptMarkdown extends StatelessWidget {
  const _ThemedGptMarkdown({
    required this.content,
    required this.isDark,
    required this.style,
  });

  final String content;
  final bool isDark;
  final TextStyle style;

  static bool _isAudioUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.wma') ||
        lower.endsWith('.opus');
  }

  @override
  Widget build(BuildContext context) {
    final gptTheme = GptMarkdownThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      highlightColor: isDark
          ? const Color(0xFF334155)
          : const Color(0xFFDBEAFE),
      linkColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      linkHoverColor: isDark
          ? const Color(0xFF93C5FD)
          : const Color(0xFF1D4ED8),
      hrLineColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      hrLineThickness: 1.0,
      h1: style.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      h2: style.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
      h3: style.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
      h4: style.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      h5: style.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      h6: style.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    );

    return GptMarkdownTheme(
      gptThemeData: gptTheme,
      child: GptMarkdown(
        content,
        style: style,
        followLinkColor: true,
        imageBuilder: _buildImageOrAudio,
        onLinkTap: (url, title) {
          if (_isAudioUrl(url) && context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                contentPadding: const EdgeInsets.all(16),
                content: AudioPlayerWidget(source: url),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildImageOrAudio(BuildContext context, String url, double? width, double? height) {
    if (_isAudioUrl(url)) {
      return AudioPlayerWidget(source: url, height: 56);
    }
    return SizedBox(
      width: width,
      height: height,
      child: Image(
        image: NetworkImage(url),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[800],
          child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
        ),
      ),
    );
  }
}

class _DeferredMarkdownContent extends StatefulWidget {
  const _DeferredMarkdownContent({required this.content, required this.isDark});

  final String content;
  final bool isDark;

  @override
  State<_DeferredMarkdownContent> createState() =>
      _DeferredMarkdownContentState();
}

class _DeferredMarkdownContentState extends State<_DeferredMarkdownContent> {
  bool _showMarkdown = false;
  Timer? _deferTimer;

  @override
  void initState() {
    super.initState();
    _deferTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _showMarkdown = true);
      }
    });
  }

  @override
  void dispose() {
    _deferTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DeferredMarkdownContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.isDark != widget.isDark) {
      _showMarkdown = false;
      _deferTimer?.cancel();
      _deferTimer = Timer(const Duration(milliseconds: 120), () {
        if (mounted) {
          setState(() => _showMarkdown = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showMarkdown) {
      return _StreamingTextContent(
        content: widget.content,
        isDark: widget.isDark,
      );
    }

    return _MarkdownBodyContent(content: widget.content, isDark: widget.isDark);
  }
}

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ToolBubble extends StatelessWidget {
  const _ToolBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsetsDirectional.only(
          start: 8,
          end: 48,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFC7D2FE),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_outlined,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  message.toolCallId != null
                      ? l10n.tool_label(message.toolCallId!)
                      : l10n.tool_unknown,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRunningIcon extends StatefulWidget {
  const _AnimatedRunningIcon({required this.color});
  final Color color;

  @override
  State<_AnimatedRunningIcon> createState() => _AnimatedRunningIconState();
}

class _AnimatedRunningIconState extends State<_AnimatedRunningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.cached_rounded,
        size: 14,
        color: widget.color,
      ),
    );
  }
}

class _GroupedToolCall {
  final String baseId;
  final String toolName;
  final ToolProviderType providerType;
  final String? providerRef;
  final Map<String, dynamic>? arguments;
  final ToolEventStatus status;
  final String? result;
  final String? error;
  final int? durationMs;
  final DateTime timestamp;

  const _GroupedToolCall({
    required this.baseId,
    required this.toolName,
    required this.providerType,
    this.providerRef,
    this.arguments,
    required this.status,
    this.result,
    this.error,
    this.durationMs,
    required this.timestamp,
  });
}

class _ToolTimeline extends StatelessWidget {
  const _ToolTimeline({required this.events});
  final List<ToolEvent> events;

  List<_GroupedToolCall> _groupEvents(List<ToolEvent> events) {
    final Map<String, _GroupedToolCall> groups = {};
    final List<String> orderedBaseIds = [];

    for (final event in events) {
      final dotIndex = event.eventId.lastIndexOf('.');
      final baseId = dotIndex != -1 ? event.eventId.substring(0, dotIndex) : event.eventId;

      if (!orderedBaseIds.contains(baseId)) {
        orderedBaseIds.add(baseId);
      }

      final existing = groups[baseId];
      if (existing == null) {
        groups[baseId] = _GroupedToolCall(
          baseId: baseId,
          toolName: event.toolName,
          providerType: event.providerType,
          providerRef: event.providerRef,
          arguments: event.arguments,
          status: event.status,
          result: event.result,
          error: event.error,
          durationMs: event.durationMs,
          timestamp: event.timestamp,
        );
      } else {
        groups[baseId] = _GroupedToolCall(
          baseId: baseId,
          toolName: event.toolName,
          providerType: event.providerType,
          providerRef: event.providerRef,
          arguments: event.arguments ?? existing.arguments,
          status: event.status,
          result: event.result ?? existing.result,
          error: event.error ?? existing.error,
          durationMs: event.durationMs ?? existing.durationMs,
          timestamp: event.timestamp,
        );
      }
    }

    return orderedBaseIds.map((id) => groups[id]!).toList();
  }

  String _formatArgs(Map<String, dynamic> args) {
    if (args.isEmpty) return '';
    try {
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(args);
    } catch (_) {
      return args.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final groupedCalls = _groupEvents(events);

    if (groupedCalls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2E).withValues(alpha: 0.6)
            : const Color(0xFFF5F7FF).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF313244).withValues(alpha: 0.8)
              : const Color(0xFFE0E5F5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF313244).withValues(alpha: 0.5)
                      : const Color(0xFFE0E5F5).withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: 16,
                  color: isDark
                      ? const Color(0xFFBAC2DE)
                      : const Color(0xFF585B70),
                ),
                const SizedBox(width: 8),
                Text(
                  'SYSTEM ACTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark
                      ? const Color(0xFFBAC2DE)
                      : const Color(0xFF585B70),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF313244) : const Color(0xFFE0E5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${groupedCalls.length} ${groupedCalls.length == 1 ? "action" : "actions"}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Grouped tool calls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupedCalls.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? const Color(0xFF313244).withValues(alpha: 0.3)
                      : const Color(0xFFE0E5F5).withValues(alpha: 0.5),
                ),
              ),
              itemBuilder: (context, index) => _ToolRowWidget(
                call: groupedCalls[index],
                isDark: isDark,
                formatArgs: _formatArgs,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ToolRowWidget extends StatefulWidget {
  const _ToolRowWidget({
    required this.call,
    required this.isDark,
    required this.formatArgs,
  });

  final _GroupedToolCall call;
  final bool isDark;
  final String Function(Map<String, dynamic>) formatArgs;

  @override
  State<_ToolRowWidget> createState() => _ToolRowWidgetState();
}

class _ToolRowWidgetState extends State<_ToolRowWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.call.status == ToolEventStatus.running ||
        widget.call.status == ToolEventStatus.failed ||
        widget.call.status == ToolEventStatus.requested ||
        widget.call.status == ToolEventStatus.approved;
  }

  @override
  void didUpdateWidget(_ToolRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call.status != widget.call.status) {
      if (widget.call.status == ToolEventStatus.running ||
          widget.call.status == ToolEventStatus.failed ||
          widget.call.status == ToolEventStatus.requested ||
          widget.call.status == ToolEventStatus.approved) {
        setState(() {
          _isExpanded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final isDark = widget.isDark;
    final isMcpTool = call.providerType == ToolProviderType.mcp;

    final iconColor = switch (call.status) {
      ToolEventStatus.completed => const Color(0xFF22C55E),
      ToolEventStatus.failed ||
      ToolEventStatus.rejected => const Color(0xFFEF4444),
      ToolEventStatus.running => const Color(0xFF3B82F6),
      ToolEventStatus.requested ||
      ToolEventStatus.approved => const Color(0xFFF59E0B),
    };

    final statusLabel = switch (call.status) {
      ToolEventStatus.requested => 'Requested',
      ToolEventStatus.approved => 'Approved',
      ToolEventStatus.rejected => 'Rejected',
      ToolEventStatus.running => 'Running',
      ToolEventStatus.completed => 'Done',
      ToolEventStatus.failed => 'Failed',
    };

    final showCodeBlock = (call.arguments != null && call.arguments!.isNotEmpty) ||
        (call.result != null && call.result!.isNotEmpty) ||
        (call.error != null && call.error!.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: showCodeBlock
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (call.status == ToolEventStatus.running)
                    _AnimatedRunningIcon(color: iconColor)
                  else
                    Icon(
                      switch (call.status) {
                        ToolEventStatus.requested => Icons.hourglass_empty_rounded,
                        ToolEventStatus.approved => Icons.check_circle_outline_rounded,
                        ToolEventStatus.rejected => Icons.block_flipped,
                        ToolEventStatus.running => Icons.cached_rounded,
                        ToolEventStatus.completed => Icons.check_circle_rounded,
                        ToolEventStatus.failed => Icons.error_rounded,
                      },
                      size: 14,
                      color: iconColor,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            call.toolName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isMcpTool) ...[
                          _InlineToolBadge(
                            label: 'MCP',
                            backgroundColor: Colors.purple.withValues(alpha: isDark ? 0.2 : 0.1),
                            textColor: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
                          ),
                        ] else if (call.providerType == ToolProviderType.lmStudioServer) ...[
                          _InlineToolBadge(
                            label: 'LM Studio',
                            backgroundColor: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                            textColor: isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C),
                          ),
                        ] else ...[
                          _InlineToolBadge(
                            label: 'LOCAL',
                            backgroundColor: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
                            textColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
                          ),
                        ],
                        const SizedBox(width: 6),
                        _InlineToolBadge(
                          label: statusLabel,
                          backgroundColor: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                          textColor: iconColor,
                        ),
                      ],
                    ),
                  ),
                  if (call.durationMs != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${call.durationMs}ms',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                  if (showCodeBlock) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showCodeBlock && _isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 22),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (call.arguments != null && call.arguments!.isNotEmpty) ...[
                      Text(
                        'Arguments:',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.formatArgs(call.arguments!),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          fontFamily: 'monospace',
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (call.result != null && call.result!.isNotEmpty) ...[
                      if (call.arguments != null && call.arguments!.isNotEmpty)
                        const SizedBox(height: 8),
                      Text(
                        'Output:',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        call.result!,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          fontFamily: 'monospace',
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (call.error != null && call.error!.isNotEmpty) ...[
                      if (call.arguments != null && call.arguments!.isNotEmpty)
                        const SizedBox(height: 8),
                      Text(
                        'Error:',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        call.error!,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                          fontFamily: 'monospace',
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineToolBadge extends StatelessWidget {
  const _InlineToolBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _AttachmentList extends StatelessWidget {
  const _AttachmentList({required this.paths, required this.isUser});

  final List<String> paths;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: paths.map((path) => _AttachmentItem(path: path)).toList(),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  const _AttachmentItem({required this.path});

  final String path;

  bool _isImage(String path) {
    final mime = path.toLowerCase();
    return mime.endsWith('.jpg') ||
        mime.endsWith('.jpeg') ||
        mime.endsWith('.png') ||
        mime.endsWith('.gif') ||
        mime.endsWith('.webp');
  }

  bool _isAudio(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp3') ||
        ext.endsWith('.wav') ||
        ext.endsWith('.ogg') ||
        ext.endsWith('.flac') ||
        ext.endsWith('.aac') ||
        ext.endsWith('.m4a') ||
        ext.endsWith('.wma') ||
        ext.endsWith('.opus');
  }

  void _viewImage(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => _ImageViewer(path: path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final file = File(path);
    final fileName = path.split('/').last;

    if (_isImage(path)) {
      return GestureDetector(
        onTap: () => _viewImage(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _FilePlaceholder(fileName: fileName),
          ),
        ),
      );
    }

    if (_isAudio(path)) {
      return AudioPlayerWidget(source: path);
    }

    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePlaceholder extends StatelessWidget {
  const _FilePlaceholder({required this.fileName});
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[800],
      child: Center(
        child: Text(
          fileName.split('.').last.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
