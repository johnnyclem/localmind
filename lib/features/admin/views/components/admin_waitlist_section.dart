import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../data/models/admin_waitlist_entry.dart';
import '../../providers/admin_providers.dart';
import 'admin_list_state.dart';

/// Waitlist tab (mobile PRD M15, T-M15-05 scope as specified for this
/// build): list entries, remove (confirm).
class AdminWaitlistSection extends ConsumerStatefulWidget {
  const AdminWaitlistSection({super.key});

  @override
  ConsumerState<AdminWaitlistSection> createState() =>
      _AdminWaitlistSectionState();
}

class _AdminWaitlistSectionState extends ConsumerState<AdminWaitlistSection> {
  String? _errorBanner;
  String? _busyId;

  String _errorMessage(Object e) {
    if (e is HyperVaultApiException) return e.message;
    return 'Something went wrong — try again.';
  }

  Future<void> _remove(AdminWaitlistEntry entry) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Remove from waitlist?',
      message:
          'Remove ${entry.email ?? entry.userId} from the waitlist? '
          'They can rejoin by signing in again.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;

    setState(() {
      _busyId = entry.userId;
      _errorBanner = null;
    });
    try {
      await ref.read(adminWaitlistProvider.notifier).remove(entry.userId);
    } catch (e) {
      if (mounted) setState(() => _errorBanner = _errorMessage(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waitlistAsync = ref.watch(adminWaitlistProvider);

    return Column(
      children: [
        if (_errorBanner != null)
          AdminInlineErrorBanner(
            message: _errorBanner!,
            onDismiss: () => setState(() => _errorBanner = null),
          ),
        Expanded(
          child: waitlistAsync.when(
            loading: () => const AdminSectionLoading(),
            error: (err, _) => AdminSectionError(
              message: _errorMessage(err),
              onRetry: () => ref.read(adminWaitlistProvider.notifier).refresh(),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const AdminSectionEmpty(
                  message: 'Nobody is waiting for access right now.',
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(adminWaitlistProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final busy = _busyId == entry.userId;
                    return _WaitlistRow(
                      entry: entry,
                      busy: busy,
                      onRemove: () => _remove(entry),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WaitlistRow extends StatelessWidget {
  final AdminWaitlistEntry entry;
  final bool busy;
  final VoidCallback onRemove;

  const _WaitlistRow({
    required this.entry,
    required this.busy,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.email ?? entry.userId,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${formatAdminDate(entry.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ShadButton.destructive(
            onPressed: busy ? null : onRemove,
            size: ShadButtonSize.sm,
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
