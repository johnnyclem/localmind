import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// `2026-07-20` style — avoids pulling in `intl`'s locale machinery for a
/// simple admin-only timestamp.
String formatAdminDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${pad(local.month)}-${pad(local.day)}';
}

/// Shared loading/empty/error scaffolding for the three admin list sections
/// (mobile PRD M15). The three states are kept visually distinct so a
/// genuinely empty list is never mistaken for a failed load, and vice versa
/// — the direct-Supabase read path (see `admin_providers.dart`) has no
/// server-side guarantee of admin access, so "failed to load" is expected
/// to be the common case for non-admins.
class AdminSectionLoading extends StatelessWidget {
  const AdminSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class AdminSectionEmpty extends StatelessWidget {
  final String message;
  const AdminSectionEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class AdminSectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AdminSectionError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedShieldQuestionMark,
              size: 32,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Inline banner for a mutation failure (create/toggle/delete), shown above
/// the list rather than replacing it — the list itself is still good.
class AdminInlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  const AdminInlineErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: TextStyle(color: colorScheme.error)),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 16,
              ),
              onPressed: onDismiss,
              tooltip: 'Dismiss',
            ),
        ],
      ),
    );
  }
}

/// Native confirm dialog for a destructive action (mobile PRD M15: destroy
/// invite / remove waitlist entry / delete account, all confirm natively).
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}
