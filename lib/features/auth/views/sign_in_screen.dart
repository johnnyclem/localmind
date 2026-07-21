import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/providers/hypervault_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../data/models/auth_gate_status.dart';
import '../providers/auth_providers.dart';

/// Entry point for HyperVault sign-in (T-M2-03/T-M2-11). Google OAuth opens
/// the system browser via Supabase's PKCE flow and returns through the
/// `hypervault://auth/callback` deep link registered in the platform
/// manifests; [AuthNotifier] picks up the resulting session automatically.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _showSelfHosted = false;
  late final TextEditingController _baseUrlController;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: ref.read(customBaseUrlProvider) ?? '',
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  void _useSelfHostedBaseUrl() {
    ref
        .read(customBaseUrlProvider.notifier)
        .setCustomBaseUrl(_baseUrlController.text);
    ref.read(capabilitiesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final isBusy = auth.status == AuthGateStatus.loading;
    final effectiveBaseUrl = ref.watch(effectiveBaseUrlProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthGateStatus.approved) {
        context.go(AppRoutes.home);
      } else if (next.status == AuthGateStatus.waitlisted) {
        context.go(AppRoutes.authWaitlist);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedSafe, size: 56),
                  const SizedBox(height: 24),
                  Text(
                    'HyperVault',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personal flight deck for everything your AI creates.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  if (auth.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        auth.errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ShadButton(
                    width: double.infinity,
                    enabled: !isBusy,
                    leading: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const HugeIcon(
                            icon: HugeIcons.strokeRoundedGoogle,
                            size: 18,
                          ),
                    onPressed: isBusy
                        ? null
                        : () {
                            ref.read(authProvider.notifier).clearError();
                            ref.read(authProvider.notifier).signInWithGoogle();
                          },
                    child: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Signing in connects this device to the same vault, memory wiki, and chats as hypervault.store.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showSelfHosted = !_showSelfHosted),
                    child: Text(
                      _showSelfHosted
                          ? 'Hide self-hosted options'
                          : 'Self-hosted deployment?',
                    ),
                  ),
                  if (_showSelfHosted) ...[
                    ShadInputFormField(
                      controller: _baseUrlController,
                      label: const Text('Deployment URL'),
                      placeholder: const Text('https://hypervault.store'),
                    ),
                    const SizedBox(height: 8),
                    ShadButton.outline(
                      width: double.infinity,
                      onPressed: _useSelfHostedBaseUrl,
                      child: const Text('Use this'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Currently connecting to $effectiveBaseUrl',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
