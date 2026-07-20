import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/routes/app_routes.dart';
import '../data/models/auth_gate_status.dart';
import '../providers/auth_providers.dart';

/// Shown when a signed-in user has no `account_access` row yet (T-M2-07).
/// Offers an invite-code redeem field; on success the gate re-resolves and
/// the router bounces to the vault.
class WaitlistScreen extends ConsumerStatefulWidget {
  /// Prefills the redeem field — set when a `?invite=<code>` deep link
  /// (`hypervault://open?invite=CODE` or `/?invite=CODE`) routed here via
  /// `lib/app.dart`'s router redirect, carried through as a `?code=` query
  /// param on this route (see `lib/features/deep_links/data/hv_deep_link.dart`).
  final String? initialCode;

  const WaitlistScreen({super.key, this.initialCode});

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  late final _codeController = TextEditingController(
    text: widget.initialCode ?? '',
  );
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    setState(() => _submitting = true);
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).redeemInviteCode(_codeController.text);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthGateStatus.approved) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("You're on the list"),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedLogout01),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedHourglass, size: 48),
                  const SizedBox(height: 20),
                  Text(
                    'HyperVault is invite-only right now.',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're signed in as ${auth.email ?? 'your account'}. "
                    'Have an invite code? Redeem it below to unlock your vault immediately.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (auth.errorMessage != null) ...[
                    Text(
                      auth.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  ShadInput(
                    controller: _codeController,
                    placeholder: const Text('HV-XXXX-XXXX'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  ShadButton(
                    width: double.infinity,
                    enabled: !_submitting,
                    onPressed: _submitting ? null : _redeem,
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Redeem code'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
