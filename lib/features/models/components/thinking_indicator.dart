import 'package:flutter/material.dart';
import 'package:localmind/core/theme/colors.dart';
import 'package:localmind/l10n/app_localizations.dart';

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key, required this.isDark});
  final bool isDark;

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Color.lerp(
                        AppColors.darkMutedText,
                        AppColors.darkAccent,
                        _controller.value,
                      )
                    : Color.lerp(
                        AppColors.lightMutedText,
                        AppColors.darkAccent,
                        _controller.value,
                      ),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        Text(
          l10n.thinking,
          style: TextStyle(
            fontSize: 12,
            color: widget.isDark
                ? AppColors.darkMutedText
                : AppColors.lightMutedText,
          ),
        ),
      ],
    );
  }
}
