import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cue/cue.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingServerTypeScreen extends ConsumerStatefulWidget {
  const OnboardingServerTypeScreen({super.key});

  @override
  ConsumerState<OnboardingServerTypeScreen> createState() =>
      _OnboardingServerTypeScreenState();
}

class _OnboardingServerTypeScreenState
    extends ConsumerState<OnboardingServerTypeScreen> {
  ServerType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = ServerType.lmStudio;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/logo.webp',
                width: 24,
                height: 24,
              ),
            ),
            Text(
              l10n.onboarding_localmind,
              style: const TextStyle(letterSpacing: 2, fontSize: 14),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => _skipOnboarding(),
            label: Text(l10n.skip),
            icon: HugeIcon(icon: HugeIcons.strokeRoundedNext),
          ),
        ],
      ),
      body: Cue.onMount(
        motion: .smooth(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Actor(
                      acts: [
                        .fadeIn(),
                        .slideY(from: 0.08),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            l10n.onboarding_connect_server,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.onboarding_connect_desc,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Actor(
                      delay: 60.ms,
                      acts: [
                        .fadeIn(),
                        .slideY(from: 0.08),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          _buildServerCard(
                            type: ServerType.onDevice,
                            title: l10n.server_type_on_device,
                            subtitle: l10n.server_type_on_device_sub,
                            iconWidget: Icon(
                              Icons.phone_android_rounded,
                              color: _selectedType == ServerType.onDevice
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            theme: theme,
                          ),
                          const SizedBox(height: 16),
                          _buildServerCard(
                            type: ServerType.lmStudio,
                            title: l10n.server_type_lm_studio,
                            subtitle: l10n.server_type_lm_studio_sub,
                            iconWidget: Icon(
                              Icons.terminal_rounded,
                              color: _selectedType == ServerType.lmStudio
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            theme: theme,
                          ),
                          const SizedBox(height: 16),
                          _buildServerCard(
                            type: ServerType.ollama,
                            title: l10n.server_type_ollama,
                            subtitle: l10n.server_type_ollama_sub,
                            iconWidget: Icon(
                              Icons.smart_toy_rounded,
                              color: _selectedType == ServerType.ollama
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            theme: theme,
                          ),
                          const SizedBox(height: 16),
                          _buildServerCard(
                            type: ServerType.openRouter,
                            title: l10n.server_type_openrouter,
                            subtitle: l10n.server_type_openrouter_sub,
                            iconWidget: HugeIcon(
                              icon: HugeIcons.strokeRoundedCloudServer,
                              color: _selectedType == ServerType.openRouter
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Actor(
              delay: 120.ms,
              acts: [
                .fadeIn(),
                .slideY(from: 0.08),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Status Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _selectedType != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedType != null
                              ? l10n.ready_continue
                              : l10n.waiting_selection,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ShadButton(
                      width: double.infinity,
                      enabled: _selectedType != null,
                      onPressed: () {
                        if (_selectedType != null) {
                          if (_selectedType == ServerType.onDevice) {
                            context.push(AppRoutes.onboardingModelDownload);
                          } else {
                            context.push(
                              AppRoutes.onboardingSetup,
                              extra: _selectedType,
                            );
                          }
                        }
                      },
                      child: Text(
                        l10n.continue_action,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom,
                    ), // Reduced bottom padding slightly for small screens
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard({
    required ServerType type,
    required String title,
    required String subtitle,
    required Widget iconWidget,
    required ThemeData theme,
    bool disabled = false,
    String? disabledReason,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: disabled
          ? () {
              if (disabledReason != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(disabledReason),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            }
          : () {
              setState(() {
                _selectedType = type;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: disabled
              ? theme.colorScheme.surface.withValues(alpha: 0.5)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected && !disabled
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected && !disabled ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: iconWidget,
                ),
                const Spacer(),
                if (disabled)
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: disabled
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2,
                color: disabled
                    ? Colors.orange.withValues(alpha: 0.7)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .updateSettings(settings.copyWith(hasCompletedOnboarding: true));
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }
}
