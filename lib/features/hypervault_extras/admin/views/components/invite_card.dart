import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_invite.dart';

/// One invite code row (spec T-M15-04): code, use count, note, status badge,
/// enable/disable switch, destroy button.
class InviteCard extends StatelessWidget {
  final HvInvite invite;
  final bool busy;
  final ValueChanged<bool> onToggleDisabled;
  final VoidCallback onDestroy;
  final VoidCallback onCopyCode;

  const InviteCard({
    super.key,
    required this.invite,
    required this.busy,
    required this.onToggleDisabled,
    required this.onDestroy,
    required this.onCopyCode,
  });

  Color _statusColor(BuildContext context) {
    if (invite.disabled) return Theme.of(context).colorScheme.outline;
    if (invite.usedUp) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(12),
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
              IconButton(
                tooltip: 'Copy code',
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCopy01,
                  size: 16,
                ),
                onPressed: onCopyCode,
              ),
              ShadBadge.secondary(
                child: Text(
                  invite.statusLabel,
                  style: TextStyle(fontSize: 10, color: _statusColor(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${invite.useCount}/${invite.maxUses} uses'
            '${invite.note != null && invite.note!.isNotEmpty ? ' · ${invite.note}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                invite.disabled ? 'Disabled' : 'Enabled',
                style: theme.textTheme.bodySmall,
              ),
              ShadSwitch(
                value: !invite.disabled,
                enabled: !busy,
                onChanged: (enabled) => onToggleDisabled(!enabled),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Destroy',
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: busy ? null : onDestroy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
