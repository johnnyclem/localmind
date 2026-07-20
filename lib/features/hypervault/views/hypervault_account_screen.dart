import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/enums.dart';
import '../data/models/hv_api_error.dart';
import '../providers/hypervault_providers.dart';

/// Sign-in + account status for the connected HyperVault deployment. Once
/// signed in and approved, a `ServerType.hyperVault` [Server] is kept in
/// sync automatically (see [hyperVaultServerSyncProvider]) and shows up in
/// the model picker like any other backend — this screen is just the
/// auth/gate surface, not the chat surface itself.
class HyperVaultAccountScreen extends ConsumerStatefulWidget {
  const HyperVaultAccountScreen({super.key});

  @override
  ConsumerState<HyperVaultAccountScreen> createState() =>
      _HyperVaultAccountScreenState();
}

class _HyperVaultAccountScreenState
    extends ConsumerState<HyperVaultAccountScreen> {
  bool _signingIn = false;
  bool _showAdvanced = false;
  late final TextEditingController _baseUrlController;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(
      text: ref.read(hyperVaultBaseUrlProvider),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Ensure Supabase is initialized from the current deployment's
      // capabilities before attempting OAuth.
      await ref.read(hyperVaultCapabilitiesProvider.future);
      await ref.read(hyperVaultAuthServiceProvider).signInWithGoogle();
    } on HvApiError catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.error)));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not start sign-in: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(hyperVaultAuthServiceProvider).signOut();
    ref.invalidate(hyperVaultGateProvider);
  }

  void _applyBaseUrl() {
    ref
        .read(hyperVaultBaseUrlProvider.notifier)
        .setBaseUrl(_baseUrlController.text);
    ref.invalidate(hyperVaultCapabilitiesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(hyperVaultSessionProvider);
    final capabilities = ref.watch(hyperVaultCapabilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HyperVault')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCloudServer,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your personal flight deck for everything your AI creates.',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (session == null) ...[
                Text(
                  'Sign in with your HyperVault account to chat through any '
                  'backend you’ve connected there, and to browse your '
                  'vault, memory wiki, and git-mind history from this app.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                ShadButton(
                  width: double.infinity,
                  enabled: !_signingIn,
                  leading: _signingIn
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const HugeIcon(icon: HugeIcons.strokeRoundedGoogle),
                  onPressed: _signIn,
                  child: const Text('Continue with Google'),
                ),
                const SizedBox(height: 8),
                capabilities.when(
                  data: (_) => const SizedBox.shrink(),
                  loading: () => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Connecting to ${ref.watch(hyperVaultBaseUrlProvider)}…',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      e is HvApiError ? e.error : 'Could not reach deployment',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      setState(() => _showAdvanced = !_showAdvanced),
                  child: Text(_showAdvanced ? 'Hide advanced' : 'Self-hosted deployment?'),
                ),
                if (_showAdvanced) ...[
                  ShadInputFormField(
                    controller: _baseUrlController,
                    label: const Text('Deployment URL'),
                    placeholder: const Text('https://hypervault.store'),
                  ),
                  const SizedBox(height: 8),
                  ShadButton.outline(
                    onPressed: _applyBaseUrl,
                    child: const Text('Use this deployment'),
                  ),
                ],
              ] else ...[
                _SignedInPanel(
                  email: session.user.email ?? session.user.id,
                  onSignOut: _signOut,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInPanel extends ConsumerWidget {
  final String email;
  final VoidCallback onSignOut;

  const _SignedInPanel({required this.email, required this.onSignOut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gate = ref.watch(hyperVaultGateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedUserCircle02),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email, style: theme.textTheme.titleSmall),
                    gate.when(
                      data: (status) => Text(
                        status == HyperVaultGateStatus.waitlisted
                            ? 'Waitlisted'
                            : 'Connected',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: status == HyperVaultGateStatus.waitlisted
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                      loading: () => Text(
                        'Checking access…',
                        style: theme.textTheme.labelSmall,
                      ),
                      error: (_, _) => Text(
                        'Could not verify access',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        gate.maybeWhen(
          data: (status) => status == HyperVaultGateStatus.waitlisted
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Your account is on the HyperVault waitlist. Redeem an '
                    'invite code or claim access from the web app, then tap '
                    'below to re-check.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
        ShadButton.outline(
          onPressed: () => ref.invalidate(hyperVaultGateProvider),
          child: const Text('Re-check access'),
        ),
        const SizedBox(height: 8),
        ShadButton.destructive(
          onPressed: onSignOut,
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
