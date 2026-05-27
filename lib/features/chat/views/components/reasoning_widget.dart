import 'package:flutter/material.dart';
import 'package:localmind/l10n/app_localizations.dart';

class ReasoningWidget extends StatefulWidget {
  final String? reasoningContent;
  final bool isStreaming;

  const ReasoningWidget({
    super.key,
    this.reasoningContent,
    this.isStreaming = false,
  });

  @override
  State<ReasoningWidget> createState() => _ReasoningWidgetState();
}

class _ReasoningWidgetState extends State<ReasoningWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isStreaming;
  }

  @override
  void didUpdateWidget(ReasoningWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !oldWidget.isStreaming) {
      _isExpanded = true;
    }
  }

  String _getLastLines(String content, int maxLines) {
    var lineCount = 0;
    for (var i = content.length - 1; i >= 0; i--) {
      if (content.codeUnitAt(i) == 10) {
        lineCount++;
        if (lineCount >= maxLines) {
          return '... ${content.substring(i + 1).trim()}';
        }
      }
    }
    return content.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasContent = widget.reasoningContent?.isNotEmpty == true;

    if (!hasContent && !widget.isStreaming) {
      return const SizedBox.shrink();
    }

    final previewText = hasContent
        ? _getLastLines(widget.reasoningContent!, 4)
        : '';
    final visibleReasoningText = widget.isStreaming
        ? previewText
        : (_isExpanded ? widget.reasoningContent! : previewText);

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1F2937).withValues(alpha: 0.5)
              : const Color(0xFFEEF2FF).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE0E7FF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.isStreaming)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  )
                else
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                const SizedBox(width: 8),
                Text(
                  l10n.thinking,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                if (widget.isStreaming) ...[
                  const SizedBox(width: 8),
                  Text(
                    _getThinkingIndicator(),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
            if (hasContent) ...[
              const SizedBox(height: 8),
              Text(
                visibleReasoningText,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF4B5563),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  final String _thinkingText = '';
  String _getThinkingIndicator() {
    if (!widget.isStreaming) return '';
    return _thinkingText;
  }
}
