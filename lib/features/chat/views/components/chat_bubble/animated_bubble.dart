import 'package:flutter/material.dart';

class AnimatedBubble extends StatelessWidget {
  const AnimatedBubble({super.key, required this.child, required this.alignment});

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
