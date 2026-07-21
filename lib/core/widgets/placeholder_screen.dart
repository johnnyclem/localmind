import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Stand-in for a screen whose epic hasn't landed yet (T-M1-02: every route
/// must be reachable from app boot even before its feature is built).
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;
  final List<List<dynamic>> icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.message = 'This is coming soon.',
    this.icon = HugeIcons.strokeRoundedConstruction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
