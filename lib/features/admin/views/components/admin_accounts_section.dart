import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/models/admin_account.dart';
import '../../providers/admin_providers.dart';
import 'admin_list_state.dart';

/// Accounts tab (mobile PRD M15, T-M15-06/07): plan upgrade/downgrade,
/// approve/revoke access, delete — all self-guarded so the signed-in admin
/// can never revoke or delete their own row from this screen.
class AdminAccountsSection extends ConsumerStatefulWidget {
  const AdminAccountsSection({super.key});

  @override
  ConsumerState<AdminAccountsSection> createState() =>
      _AdminAccountsSectionState();
}

class _AdminAccountsSectionState extends ConsumerState<AdminAccountsSection> {
  String? _errorBanner;
  String? _busyId;

  String _errorMessage(Object e) {
    if (e is HyperVaultApiException) return e.message;
    return 'Something went wrong — try again.';
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    setState(() {
      _busyId = id;
      _errorBanner = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _errorBanner = _errorMessage(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _togglePlan(AdminAccount account) {
    final nextPlan = account.plan == 'pro' ? 'free' : 'pro';
    return _run(
      account.id,
      () => ref
          .read(adminAccountsProvider.notifier)
          .setPlan(account.id, nextPlan),
    );
  }

  Future<void> _toggleApproved(AdminAccount account) {
    return _run(
      account.id,
      () => ref
          .read(adminAccountsProvider.notifier)
          .setApproved(account.id, !account.hasAccess),
    );
  }

  Future<void> _delete(AdminAccount account) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete account?',
      message:
          'Permanently delete ${account.email ?? account.id} and everything '
          'they saved?',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    await _run(
      account.id,
      () => ref.read(adminAccountsProvider.notifier).delete(account.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(adminAccountsProvider);
    final selfId = ref.watch(authProvider).user?.id;

    return Column(
      children: [
        if (_errorBanner != null)
          AdminInlineErrorBanner(
            message: _errorBanner!,
            onDismiss: () => setState(() => _errorBanner = null),
          ),
        Expanded(
          child: accountsAsync.when(
            loading: () => const AdminSectionLoading(),
            error: (err, _) => AdminSectionError(
              message: _errorMessage(err),
              onRetry: () => ref.read(adminAccountsProvider.notifier).refresh(),
            ),
            data: (accounts) {
              if (accounts.isEmpty) {
                return const AdminSectionEmpty(message: 'No accounts found.');
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(adminAccountsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final isSelf = account.id == selfId;
                    final busy = _busyId == account.id;
                    return _AccountRow(
                      account: account,
                      isSelf: isSelf,
                      busy: busy,
                      onTogglePlan: () => _togglePlan(account),
                      onToggleApproved: () => _toggleApproved(account),
                      onDelete: () => _delete(account),
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

class _AccountRow extends StatelessWidget {
  final AdminAccount account;
  final bool isSelf;
  final bool busy;
  final VoidCallback onTogglePlan;
  final VoidCallback onToggleApproved;
  final VoidCallback onDelete;

  const _AccountRow({
    required this.account,
    required this.isSelf,
    required this.busy,
    required this.onTogglePlan,
    required this.onToggleApproved,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPro = account.plan == 'pro';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.email ?? account.id,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelf) ...[
                const SizedBox(width: 6),
                const ShadBadge.secondary(child: Text('You')),
              ],
              const SizedBox(width: 6),
              isPro
                  ? const ShadBadge(child: Text('Pro'))
                  : const ShadBadge.outline(child: Text('Free')),
              const SizedBox(width: 6),
              account.hasAccess
                  ? const ShadBadge.secondary(child: Text('Approved'))
                  : const ShadBadge.outline(child: Text('Waitlisted')),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (account.displayName != null &&
                  account.displayName!.isNotEmpty)
                account.displayName!,
              if (account.vanitySubdomain != null &&
                  account.vanitySubdomain!.isNotEmpty)
                '${account.vanitySubdomain}.vault.cool',
              formatAdminDate(account.createdAt),
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton.outline(
                onPressed: busy ? null : onTogglePlan,
                size: ShadButtonSize.sm,
                child: Text(isPro ? 'Downgrade to free' : 'Upgrade to pro'),
              ),
              ShadButton.outline(
                onPressed: (busy || (isSelf && account.hasAccess))
                    ? null
                    : onToggleApproved,
                size: ShadButtonSize.sm,
                child: Text(account.hasAccess ? 'Revoke' : 'Approve'),
              ),
              ShadButton.destructive(
                onPressed: (busy || isSelf) ? null : onDelete,
                size: ShadButtonSize.sm,
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
