import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/features/chat/providers/chat_providers.dart';

class SmartReplyChips extends ConsumerStatefulWidget {
  const SmartReplyChips({super.key, required this.onSend});
  final ValueChanged<String> onSend;

  @override
  ConsumerState<SmartReplyChips> createState() => _SmartReplyChipsState();
}

class _SmartReplyChipsState extends ConsumerState<SmartReplyChips>
    with TickerProviderStateMixin {
  List<String> _previousSuggestions = [];
  late AnimationController _controller;
  List<Animation<double>> _fadeAnimations = [];
  List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _updateAnimations(List<String> suggestions) {
    if (suggestions.isEmpty) {
      _previousSuggestions = [];
      return;
    }
    if (_listsEqual(suggestions, _previousSuggestions)) return;

    _previousSuggestions = List.from(suggestions);

    _fadeAnimations = List.generate(suggestions.length, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.8),
            (0.3 + index * 0.1).clamp(0.2, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(suggestions.length, (index) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.8),
            (0.3 + index * 0.1).clamp(0.2, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(smartRepliesProvider);
    final suggestions = suggestionsAsync.asData?.value ?? [];

    if (suggestions.isEmpty) {
      _previousSuggestions = [];
      return const SizedBox.shrink();
    }

    _updateAnimations(suggestions);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final label = suggestions[index];
            final fadeAnimation = index < _fadeAnimations.length
                ? _fadeAnimations[index]
                : const AlwaysStoppedAnimation(1.0);
            final slideAnimation = index < _slideAnimations.length
                ? _slideAnimations[index]
                : const AlwaysStoppedAnimation(Offset.zero);

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: GestureDetector(
                  onTap: () => widget.onSend(label),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Colors.white.withValues(alpha: 0.10),
                                    Colors.white.withValues(alpha: 0.05),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.70),
                                    Colors.white.withValues(alpha: 0.40),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.80),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
