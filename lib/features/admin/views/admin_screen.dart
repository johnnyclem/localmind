import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'components/admin_accounts_section.dart';
import 'components/admin_invites_section.dart';
import 'components/admin_waitlist_section.dart';

enum _AdminTab { invites, waitlist, accounts }

/// Admin (owner-only) screen — mobile PRD M15. Reachable at
/// [AppRoutes.admin] ('/admin'), unconditionally linked from the sidebar
/// nav (hiding the nav entry for non-admins is handled elsewhere).
///
/// There is no reliable client-side "am I an admin" signal, so this screen
/// is reachable by anyone; every list load and mutation gracefully
/// degrades to an error state (derived from a 403 on the mutation REST
/// routes, or a failed direct-Supabase read for the lists) rather than
/// assuming admin access. The server is the only real gate.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  _AdminTab _tab = _AdminTab.invites;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ShadTabs<_AdminTab>(
            value: _tab,
            onChanged: (value) => setState(() => _tab = value),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: [
              ShadTab(
                value: _AdminTab.invites,
                expandContent: true,
                content: const AdminInvitesSection(),
                child: const _TabLabel(
                  icon: HugeIcons.strokeRoundedTicket01,
                  label: 'Invites',
                ),
              ),
              ShadTab(
                value: _AdminTab.waitlist,
                expandContent: true,
                content: const AdminWaitlistSection(),
                child: const _TabLabel(
                  icon: HugeIcons.strokeRoundedUserAccount,
                  label: 'Waitlist',
                ),
              ),
              ShadTab(
                value: _AdminTab.accounts,
                expandContent: true,
                content: const AdminAccountsSection(),
                child: const _TabLabel(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  label: 'Accounts',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;

  const _TabLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, size: 16),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
