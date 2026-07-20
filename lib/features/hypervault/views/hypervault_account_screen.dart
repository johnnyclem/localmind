import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/storage_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../hypervault_vault/data/hv_vault_cache.dart';
import '../data/hv_invite_redeem.dart';
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
    // Cached vault/artifact data is keyed per HyperVault user id but still
    // shouldn't linger on a shared device once nobody's signed in.
    await HvVaultCache.clearCache(ref.read(sharedPreferencesProvider));
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
                  ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCloudServer,
                        color: theme.colorScheme.primary,
                      ),
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
                Semantics(
                  button: true,
                  enabled: !_signingIn,
                  label: _signingIn
                      ? 'Continue with Google, signing in'
                      : 'Continue with Google',
                  child: SizedBox(
                    height: 44,
                    child: ShadButton(
                      width: double.infinity,
                      enabled: !_signingIn,
                      leading: _signingIn
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const HugeIcon(
                              icon: HugeIcons.strokeRoundedGoogle,
                            ),
                      onPressed: _signIn,
                      child: const Text('Continue with Google'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                capabilities.when(
                  data: (_) => const SizedBox.shrink(),
                  loading: () => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        'Connecting to ${ref.watch(hyperVaultBaseUrlProvider)}…',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        e is HvApiError
                            ? e.error
                            : 'Could not reach deployment',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  toggled: _showAdvanced,
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _showAdvanced = !_showAdvanced),
                      child: Text(
                        _showAdvanced
                            ? 'Hide advanced'
                            : 'Self-hosted deployment?',
                      ),
                    ),
                  ),
                ),
                if (_showAdvanced) ...[
                  ShadInputFormField(
                    controller: _baseUrlController,
                    label: const Text('Deployment URL'),
                    placeholder: const Text('https://hypervault.store'),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    button: true,
                    hint: 'Applies the deployment URL above',
                    child: ShadButton.outline(
                      onPressed: _applyBaseUrl,
                      child: const Text('Use this deployment'),
                    ),
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
              const ExcludeSemantics(
                child: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle02),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email, style: theme.textTheme.titleSmall),
                    Semantics(
                      liveRegion: true,
                      child: gate.when(
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
              ? const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _InviteRedeemForm(),
                )
              : const _FeatureHub(),
          orElse: () => const SizedBox.shrink(),
        ),
        SizedBox(
          height: 44,
          child: ShadButton.outline(
            onPressed: () => ref.invalidate(hyperVaultGateProvider),
            child: const Text('Re-check access'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ShadButton.destructive(
            onPressed: onSignOut,
            child: const Text('Sign out'),
          ),
        ),
      ],
    );
  }
}

/// Lets a waitlisted user unlock their account with an invite code without
/// leaving the app. Redeems via [HyperVaultAuthService.redeemInviteCode]
/// (a direct Supabase RPC — see that method's doc comment for why this
/// doesn't call the REST `/api/invite/redeem` route).
class _InviteRedeemForm extends ConsumerStatefulWidget {
  const _InviteRedeemForm();

  @override
  ConsumerState<_InviteRedeemForm> createState() => _InviteRedeemFormState();
}

class _InviteRedeemFormState extends ConsumerState<_InviteRedeemForm> {
  final _codeController = TextEditingController();
  bool _redeeming = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _redeeming = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(hyperVaultAuthServiceProvider)
          .redeemInviteCode(code);
      if (hvRedeemResultIsSuccess(result)) {
        _codeController.clear();
        ref.invalidate(hyperVaultGateProvider);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Invite code redeemed — welcome!')),
          );
        }
      } else if (mounted) {
        setState(
          () => _error =
              hvRedeemMessages[result] ?? 'Could not redeem that code.',
        );
      }
    } on HvApiError catch (e) {
      if (mounted) setState(() => _error = e.error);
    } catch (e) {
      if (mounted) setState(() => _error = 'Network hiccup — try again.');
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your account is on the HyperVault waitlist. Enter an invite code '
          'to unlock it, or claim access from the web app and tap "Re-check '
          'access" below.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        ShadInputFormField(
          controller: _codeController,
          label: const Text('Invite code'),
          placeholder: const Text('HV-XXXX-XXXX'),
          textCapitalization: TextCapitalization.characters,
          enabled: !_redeeming,
          onSubmitted: (_) => _redeem(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ShadButton(
            width: double.infinity,
            enabled: !_redeeming,
            leading: _redeeming
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onPressed: _redeem,
            child: const Text('Redeem invite code'),
          ),
        ),
      ],
    );
  }
}

class _HubTile {
  final String route;
  final String label;
  final List<List<dynamic>> icon;

  const _HubTile(this.route, this.label, this.icon);
}

const _hubTiles = [
  _HubTile(
    AppRoutes.hyperVaultVault,
    'Vault',
    HugeIcons.strokeRoundedFile01,
  ),
  _HubTile(
    AppRoutes.hyperVaultMemory,
    'Memory',
    HugeIcons.strokeRoundedBrain,
  ),
  _HubTile(
    AppRoutes.hyperVaultBackends,
    'LLM Backends',
    HugeIcons.strokeRoundedCloudServer,
  ),
  _HubTile(
    AppRoutes.hyperVaultMcp,
    'MCP Tools',
    HugeIcons.strokeRoundedServerStack02,
  ),
  _HubTile(
    AppRoutes.hyperVaultImport,
    'Import History',
    HugeIcons.strokeRoundedFileImport,
  ),
  _HubTile(
    AppRoutes.hyperVaultDomains,
    'Domains & Upgrade',
    HugeIcons.strokeRoundedGlobe,
  ),
  _HubTile(
    AppRoutes.hyperVaultThemes,
    'Themes',
    HugeIcons.strokeRoundedPaintBoard,
  ),
  _HubTile(
    AppRoutes.hyperVaultAdmin,
    'Admin',
    HugeIcons.strokeRoundedShieldUser,
  ),
];

/// Entry points into every HyperVault feature area, shown once the account
/// is signed in and approved. Kept as one grid on the account screen rather
/// than a dozen individual sidebar entries.
class _FeatureHub extends StatelessWidget {
  const _FeatureHub();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: [
          for (final tile in _hubTiles)
            Semantics(
              button: true,
              label: tile.label,
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push(tile.route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(minHeight: 44),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: HugeIcon(
                            icon: tile.icon,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tile.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
