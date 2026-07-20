import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/models/enums.dart';
import '../../../hypervault/data/models/hv_api_error.dart';
import '../../../hypervault/providers/hypervault_providers.dart';
import '../data/models/hv_invite.dart';
import '../providers/hv_admin_providers.dart';
import 'components/invite_card.dart';

/// Admin console (spec docs/mobile/prd/15-admin.md). The client can't detect
/// admin status ahead of time — there's no capabilities field for it — so
/// this screen's entry point is shown to any approved user and the server is
/// the actual gate: every mutating call 403s for a non-admin, and the first
/// 403 flips this screen into a read-only "Admin access required" state.
///
/// There's also no `GET` list endpoint for invites/waitlist/accounts (backend
/// gap flagged in the PRD), so account/waitlist actions take a raw id typed
/// in by the admin, and the invite list only ever shows codes created or
/// edited this session.
class HvAdminScreen extends ConsumerStatefulWidget {
  const HvAdminScreen({super.key});

  @override
  ConsumerState<HvAdminScreen> createState() => _HvAdminScreenState();
}

class _HvAdminScreenState extends ConsumerState<HvAdminScreen> {
  bool _accessDenied = false;

  void _handleError(Object e) {
    final messenger = ScaffoldMessenger.of(context);
    if (e is HvApiError) {
      if (e.status == 403) {
        setState(() => _accessDenied = true);
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(hyperVaultSessionProvider);
    final gate = ref.watch(hyperVaultGateProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: Text('Sign in to HyperVault first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: SafeArea(
        child: gate.when(
          data: (status) {
            if (status != HyperVaultGateStatus.approved) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Your account isn\'t approved yet.'),
                ),
              );
            }
            if (_accessDenied) {
              return _AccessDeniedView(
                onRetry: () => setState(() => _accessDenied = false),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                ShadCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedShieldUser,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Owner-only actions. Non-admin accounts get an '
                          '"Admin access required" error from every action below.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Invite codes', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                _CreateInviteForm(onError: _handleError),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final invites = ref.watch(hvAdminInvitesProvider);
                    if (invites.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Codes you create appear here (once, this session — '
                          'there\'s no list endpoint to re-fetch them).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final invite in invites)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _InviteRow(
                              invite: invite,
                              onError: _handleError,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text('Waitlist', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'No list endpoint — remove an entry by its user id.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 10),
                _WaitlistRemoveForm(onError: _handleError),
                const SizedBox(height: 28),
                Text('Accounts', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'No lookup/search — act on a raw account id.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 10),
                _AccountActionsForm(onError: _handleError),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              err is HvApiError ? err.error : 'Could not check access.',
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _AccessDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedShield01,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Admin access required',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This account isn\'t an admin on this HyperVault deployment.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ShadButton.outline(onPressed: onRetry, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}

class _CreateInviteForm extends ConsumerStatefulWidget {
  final void Function(Object e) onError;

  const _CreateInviteForm({required this.onError});

  @override
  ConsumerState<_CreateInviteForm> createState() => _CreateInviteFormState();
}

class _CreateInviteFormState extends ConsumerState<_CreateInviteForm> {
  final _maxUsesController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _maxUsesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final maxUses = int.tryParse(_maxUsesController.text.trim()) ?? 1;
    setState(() => _busy = true);
    try {
      final invite = await ref
          .read(hvAdminServiceProvider)
          .createInvite(maxUses: maxUses, note: _noteController.text);
      ref.read(hvAdminInvitesProvider.notifier).prepend(invite);
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Minted ${invite.code}.')));
      }
    } catch (e) {
      widget.onError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: ShadInputFormField(
                  controller: _maxUsesController,
                  label: const Text('Max uses'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ShadInputFormField(
                  controller: _noteController,
                  label: const Text('Note (optional)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShadButton(
            width: double.infinity,
            enabled: !_busy,
            leading: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const HugeIcon(
                    icon: HugeIcons.strokeRoundedTicket01,
                    size: 16,
                  ),
            onPressed: _create,
            child: Text(_busy ? 'Minting…' : 'Mint invite code'),
          ),
        ],
      ),
    );
  }
}

class _InviteRow extends ConsumerStatefulWidget {
  final HvInvite invite;
  final void Function(Object e) onError;

  const _InviteRow({required this.invite, required this.onError});

  @override
  ConsumerState<_InviteRow> createState() => _InviteRowState();
}

class _InviteRowState extends ConsumerState<_InviteRow> {
  bool _busy = false;

  Future<void> _toggleDisabled(bool disabled) async {
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(hvAdminServiceProvider)
          .setInviteDisabled(widget.invite.id, disabled);
      ref.read(hvAdminInvitesProvider.notifier).replace(updated);
    } catch (e) {
      widget.onError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _destroy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Destroy invite code ${widget.invite.code}?'),
        content: const Text(
          'Accounts already redeemed with it keep their access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Destroy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(hvAdminServiceProvider).deleteInvite(widget.invite.id);
      ref.read(hvAdminInvitesProvider.notifier).remove(widget.invite.id);
    } catch (e) {
      widget.onError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.invite.code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return InviteCard(
      invite: widget.invite,
      busy: _busy,
      onToggleDisabled: _toggleDisabled,
      onDestroy: _destroy,
      onCopyCode: _copyCode,
    );
  }
}

class _WaitlistRemoveForm extends ConsumerStatefulWidget {
  final void Function(Object e) onError;

  const _WaitlistRemoveForm({required this.onError});

  @override
  ConsumerState<_WaitlistRemoveForm> createState() =>
      _WaitlistRemoveFormState();
}

class _WaitlistRemoveFormState extends ConsumerState<_WaitlistRemoveForm> {
  final _idController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from waitlist?'),
        content: Text('User $id will need a new invite to unlock their vault.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(hvAdminServiceProvider).removeFromWaitlist(id);
      _idController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $id from the waitlist.')),
        );
      }
    } catch (e) {
      widget.onError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: ShadInputFormField(
              controller: _idController,
              label: const Text('Waitlist user id'),
              placeholder: const Text('uuid'),
            ),
          ),
          const SizedBox(width: 10),
          ShadButton.destructive(
            enabled: !_busy,
            onPressed: _remove,
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _AccountActionsForm extends ConsumerStatefulWidget {
  final void Function(Object e) onError;

  const _AccountActionsForm({required this.onError});

  @override
  ConsumerState<_AccountActionsForm> createState() =>
      _AccountActionsFormState();
}

class _AccountActionsFormState extends ConsumerState<_AccountActionsForm> {
  final _idController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _plan = 'pro';
  bool _busy = false;

  @override
  void dispose() {
    _idController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String get _accountId => _idController.text.trim();

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an account id first.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      widget.onError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndRun(
    Future<void> Function() action, {
    required String title,
    required String content,
    String? successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(action, successMessage: successMessage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadInputFormField(
            controller: _idController,
            label: const Text('Account id'),
            placeholder: const Text('uuid'),
          ),
          const SizedBox(height: 12),
          Text('Plan', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Free'),
                selected: _plan == 'free',
                onSelected: (_) => setState(() => _plan = 'free'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Pro'),
                selected: _plan == 'pro',
                onSelected: (_) => setState(() => _plan = 'pro'),
              ),
              const SizedBox(width: 10),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                enabled: !_busy,
                onPressed: () => _run(
                  () => ref
                      .read(hvAdminServiceProvider)
                      .updateAccount(_accountId, plan: _plan),
                  successMessage: 'Plan set to $_plan.',
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ShadInputFormField(
                  controller: _displayNameController,
                  label: const Text('Display name'),
                ),
              ),
              const SizedBox(width: 10),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                enabled: !_busy,
                onPressed: () => _run(
                  () => ref
                      .read(hvAdminServiceProvider)
                      .updateAccount(
                        _accountId,
                        displayName: _displayNameController.text,
                      ),
                  successMessage: 'Display name updated.',
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton.outline(
                enabled: !_busy,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserAdd01,
                  size: 14,
                ),
                onPressed: () => _run(
                  () => ref
                      .read(hvAdminServiceProvider)
                      .updateAccount(_accountId, approved: true),
                  successMessage: 'Access approved.',
                ),
                child: const Text('Approve'),
              ),
              ShadButton.outline(
                enabled: !_busy,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserRemove01,
                  size: 14,
                ),
                onPressed: () => _confirmAndRun(
                  () => ref
                      .read(hvAdminServiceProvider)
                      .updateAccount(_accountId, approved: false),
                  title: 'Revoke access?',
                  content:
                      'This account will need a new invite to get back in.',
                  successMessage: 'Access revoked.',
                ),
                child: const Text('Revoke'),
              ),
              ShadButton.destructive(
                enabled: !_busy,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 14,
                ),
                onPressed: () => _confirmAndRun(
                  () => ref
                      .read(hvAdminServiceProvider)
                      .deleteAccount(_accountId),
                  title: 'Delete account $_accountId?',
                  content:
                      'Permanently deletes the account and everything it saved. This cannot be undone.',
                  successMessage: 'Account deleted.',
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'The server refuses revoke/delete on your own account regardless '
              'of what id you type here.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
