import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../data/models/admin_invite.dart';
import '../../providers/admin_providers.dart';
import 'admin_list_state.dart';

/// Invite codes tab (mobile PRD M15, T-M15-03/04): create, list,
/// enable/disable, destroy.
class AdminInvitesSection extends ConsumerStatefulWidget {
  const AdminInvitesSection({super.key});

  @override
  ConsumerState<AdminInvitesSection> createState() =>
      _AdminInvitesSectionState();
}

class _AdminInvitesSectionState extends ConsumerState<AdminInvitesSection> {
  String? _errorBanner;
  String? _busyId;

  String _errorMessage(Object e) {
    if (e is HyperVaultApiException) return e.message;
    return 'Something went wrong — try again.';
  }

  Future<void> _openCreateDialog() async {
    final maxUsesController = TextEditingController(text: '1');
    final noteController = TextEditingController();
    var busy = false;
    String? error;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create invite code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInput(
                  controller: maxUsesController,
                  keyboardType: TextInputType.number,
                  placeholder: const Text('Max uses (default 1)'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: noteController,
                  placeholder: const Text('Note (optional)'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        setDialogState(() => busy = true);
                        final maxUses = int.tryParse(
                          maxUsesController.text.trim(),
                        );
                        try {
                          await ref
                              .read(adminInvitesProvider.notifier)
                              .create(
                                maxUses: maxUses,
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                              );
                          if (context.mounted) Navigator.of(context).pop(true);
                        } catch (e) {
                          setDialogState(() {
                            busy = false;
                            error = _errorMessage(e);
                          });
                        }
                      },
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
    maxUsesController.dispose();
    noteController.dispose();
    if (created == true && mounted) {
      setState(() => _errorBanner = null);
    }
  }

  Future<void> _toggleDisabled(AdminInvite invite) async {
    setState(() {
      _busyId = invite.id;
      _errorBanner = null;
    });
    try {
      await ref
          .read(adminInvitesProvider.notifier)
          .setDisabled(invite.id, !invite.disabled);
    } catch (e) {
      if (mounted) setState(() => _errorBanner = _errorMessage(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _destroy(AdminInvite invite) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Destroy invite code?',
      message: 'Destroy invite code ${invite.code}? This cannot be undone.',
      confirmLabel: 'Destroy',
    );
    if (!confirmed) return;

    setState(() {
      _busyId = invite.id;
      _errorBanner = null;
    });
    try {
      await ref.read(adminInvitesProvider.notifier).delete(invite.id);
    } catch (e) {
      if (mounted) setState(() => _errorBanner = _errorMessage(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(adminInvitesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ShadButton(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedTicket01),
              onPressed: _openCreateDialog,
              child: const Text('Create invite'),
            ),
          ),
        ),
        if (_errorBanner != null)
          AdminInlineErrorBanner(
            message: _errorBanner!,
            onDismiss: () => setState(() => _errorBanner = null),
          ),
        Expanded(
          child: invitesAsync.when(
            loading: () => const AdminSectionLoading(),
            error: (err, _) => AdminSectionError(
              message: _errorMessage(err),
              onRetry: () => ref.read(adminInvitesProvider.notifier).refresh(),
            ),
            data: (invites) {
              if (invites.isEmpty) {
                return const AdminSectionEmpty(
                  message: 'No invite codes yet — create one above.',
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(adminInvitesProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: invites.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final invite = invites[index];
                    final busy = _busyId == invite.id;
                    return _InviteRow(
                      invite: invite,
                      busy: busy,
                      onToggle: () => _toggleDisabled(invite),
                      onDestroy: () => _destroy(invite),
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

class _InviteRow extends StatelessWidget {
  final AdminInvite invite;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onDestroy;

  const _InviteRow({
    required this.invite,
    required this.busy,
    required this.onToggle,
    required this.onDestroy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget statusBadge = invite.disabled
        ? const ShadBadge.outline(child: Text('Disabled'))
        : invite.isExhausted
        ? const ShadBadge.secondary(child: Text('Used up'))
        : const ShadBadge(child: Text('Active'));

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
                  invite.code,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              statusBadge,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${invite.useCount}/${invite.maxUses} uses · ${formatAdminDate(invite.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (invite.note != null && invite.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              invite.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadButton.outline(
                onPressed: busy ? null : onToggle,
                size: ShadButtonSize.sm,
                child: Text(invite.disabled ? 'Enable' : 'Disable'),
              ),
              const SizedBox(width: 8),
              ShadButton.destructive(
                onPressed: busy ? null : onDestroy,
                size: ShadButtonSize.sm,
                child: const Text('Destroy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
