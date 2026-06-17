import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:localmind/core/theme/colors.dart';

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

class _ReasoningWidgetState extends State<ReasoningWidget> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isStreaming;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReasoningWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !oldWidget.isStreaming) {
      setState(() {
        _isExpanded = true;
        _animationController.forward();
      });
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceInput
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent glowing line
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    InkWell(
                      onTap: _toggleExpand,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(11),
                        bottomRight: Radius.circular(11),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // Brain / thinking icon
                            Icon(
                              Icons.psychology_outlined,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkMutedText
                                  : AppColors.lightMutedText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.thinking,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: isDark
                                    ? const Color(0xFFBAC2DE)
                                    : const Color(0xFF585B70),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.isStreaming) ...[
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Expand Icon with rotation
                            RotationTransition(
                              turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkMutedText
                                    : AppColors.lightMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expandable content
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GptMarkdownTheme(
                              gptThemeData: GptMarkdownThemeData(
                                brightness: isDark ? Brightness.dark : Brightness.light,
                                highlightColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                linkColor: theme.colorScheme.primary,
                              ),
                              child: GptMarkdown(
                                widget.reasoningContent ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
