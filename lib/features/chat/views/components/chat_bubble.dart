import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../../../core/models/enums.dart';
import '../../data/models/message.dart';
import 'code_block.dart';
import 'message_action_bar.dart';
import 'processing_indicator.dart';
import 'typing_indicator.dart';
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
                MarkdownBody(
                  data: message.content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  shrinkWrap: true,
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

class _MarkdownContent extends StatelessWidget {
  const _MarkdownContent({required this.content, required this.isDark});

  final String content;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 15,
          height: 1.5,
        ),
        h1: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        h4: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        code: TextStyle(
          backgroundColor: isDark
              ? const Color(0xFF2D2D2D)
              : const Color(0xFFE8E8E8),
          color: isDark ? const Color(0xFF9CDCFE) : const Color(0xFF001080),
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquote: TextStyle(
          color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
              width: 3,
            ),
          ),
        ),
        blockquotePadding: EdgeInsetsDirectional.only(
          start: 16,
        ).resolve(Directionality.of(context)),
        listBullet: TextStyle(color: isDark ? Colors.white : Colors.black),
        tableHead: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
        tableBody: TextStyle(color: isDark ? Colors.white : Colors.black),
        tableBorder: TableBorder.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
            ),
          ),
        ),
        a: TextStyle(
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          decoration: TextDecoration.underline,
        ),
      ),
      builders: {'code': CodeBlockBuilder(isDark: isDark)},
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDark;

  CodeBlockBuilder({required this.isDark});

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final code = element.textContent;
    String? language;

    if (element.attributes.containsKey('class')) {
      final classes = element.attributes['class']!;
      final langMatch = RegExp(r'language-(\w+)').firstMatch(classes);
      if (langMatch != null) {
        language = langMatch.group(1);
      }
    }

    return CodeBlock(code: code, language: language);
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
