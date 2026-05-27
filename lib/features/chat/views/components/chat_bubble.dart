import 'dart:async';
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

class _ToolTimeline extends StatelessWidget {
  const _ToolTimeline({required this.events});
  final List<ToolEvent> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                Icon(
                  Icons.troubleshoot,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  'Tools',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ...events.map((event) => _buildEventRow(context, event, isDark)),
        ],
      ),
    );
  }

  Widget _buildEventRow(BuildContext context, ToolEvent event, bool isDark) {
    final iconData = switch (event.status) {
      ToolEventStatus.requested => Icons.hourglass_empty,
      ToolEventStatus.approved => Icons.check_circle_outline,
      ToolEventStatus.rejected => Icons.cancel_outlined,
      ToolEventStatus.running => Icons.play_circle_outline,
      ToolEventStatus.completed => Icons.check_circle,
      ToolEventStatus.failed => Icons.error_outline,
    };
    final iconColor = switch (event.status) {
      ToolEventStatus.completed => const Color(0xFF22C55E),
      ToolEventStatus.failed ||
      ToolEventStatus.rejected => const Color(0xFFEF4444),
      ToolEventStatus.running ||
      ToolEventStatus.requested => const Color(0xFFF59E0B),
      ToolEventStatus.approved => const Color(0xFF3B82F6),
    };
    final label = switch (event.status) {
      ToolEventStatus.requested => 'Requested',
      ToolEventStatus.approved => 'Approved',
      ToolEventStatus.rejected => 'Rejected',
      ToolEventStatus.running => 'Running',
      ToolEventStatus.completed => 'Done',
      ToolEventStatus.failed => 'Failed',
    };
    final l10n = AppLocalizations.of(context)!;
    final isMcpTool = event.providerType == ToolProviderType.mcp;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(iconData, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        event.toolName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isMcpTool) ...[
                      _InlineToolBadge(label: l10n.beta_label, isDark: isDark),
                      const SizedBox(width: 4),
                      _InlineToolBadge(
                        label: l10n.experimental_label,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (event.arguments != null && event.arguments!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatArgs(event.arguments!),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (event.result != null && event.result!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '→ ${event.result}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF166534),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (event.error != null && event.error!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '✕ ${event.error}',
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xFFEF4444),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (event.durationMs != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      '${event.durationMs}ms',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatArgs(Map<String, dynamic> args) {
    return args.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}

class _InlineToolBadge extends StatelessWidget {
  const _InlineToolBadge({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: isDark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFB45309),
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
