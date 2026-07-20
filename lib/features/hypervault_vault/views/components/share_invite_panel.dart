import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../providers/hv_vault_providers.dart';

/// Invite-by-email + current-access list for one artifact
/// (docs/mobile/prd/05-connections-sharing.md T-M5-03/04). Owner-only per the
/// API; the signed-in HyperVault user is always the owner of their own vault.
class ShareInvitePanel extends ConsumerStatefulWidget {
  final String artifactRef;

  const ShareInvitePanel({super.key, required this.artifactRef});

  @override
  ConsumerState<ShareInvitePanel> createState() => _ShareInvitePanelState();
}

class _ShareInvitePanelState extends ConsumerState<ShareInvitePanel> {
  final _emailController = TextEditingController();
  bool _inviting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _inviting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final (_, message) = await ref
          .read(hvVaultServiceProvider)
          .share(artifactRef: widget.artifactRef, email: email);
      _emailController.clear();
      ref.invalidate(hvSharesProvider(widget.artifactRef));
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _revoke(String shareId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke access?'),
        content: const Text('They will no longer be able to open this artifact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(hvVaultServiceProvider).unshare(shareId);
      ref.invalidate(hvSharesProvider(widget.artifactRef));
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharesAsync = ref.watch(hvSharesProvider(widget.artifactRef));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite a user', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          'The invitee must already have a HyperVault account.',
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ShadInput(
                controller: _emailController,
                placeholder: const Text('someone@example.com'),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 8),
            ShadButton(
              enabled: !_inviting,
              onPressed: _invite,
              child: const Text('Invite'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Has access', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        sharesAsync.when(
          data: (shares) => shares.isEmpty
              ? Text(
                  'Only you.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: shares
                      .map(
                        (s) => InputChip(
                          label: Text(s.displayName?.isNotEmpty == true ? s.displayName! : s.email),
                          onDeleted: () => _revoke(s.id),
                          deleteIcon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 14),
                        ),
                      )
                      .toList(),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text(
            e is HvApiError ? e.error : 'Could not load access list.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }
}
