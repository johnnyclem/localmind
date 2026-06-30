import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cue/cue.dart';

import '../../../core/models/enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../../on_device/providers/foreground_download_providers.dart';
import '../../servers/data/models/server.dart';
import '../../servers/providers/server_providers.dart';
import '../../../core/providers/device_info_providers.dart';
import 'components/model_download_components.dart';

class OnboardingModelDownloadScreen extends ConsumerStatefulWidget {
  const OnboardingModelDownloadScreen({super.key});

  @override
  ConsumerState<OnboardingModelDownloadScreen> createState() =>
      _OnboardingModelDownloadScreenState();
}

class _OnboardingModelDownloadScreenState
    extends ConsumerState<OnboardingModelDownloadScreen> {
  bool _isCreatingServer = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final models = ref.watch(onDeviceModelsProvider);
    final downloadedModelsAsync = ref.watch(downloadedModelsProvider);
    final downloadStates = ref.watch(foregroundDownloadNotifierProvider);
    final deviceMemoryAsync = ref.watch(deviceMemoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.download_model_title)),
      body: SafeArea(
        child: Cue.onMount(
          motion: .smooth(),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  children: [
                    Actor(
                      acts: [.fadeIn(), .slideY(from: 0.08)],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.download_model_desc,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!Platform.isAndroid && !Platform.isIOS)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.on_device_android_only,
                                      style: const TextStyle(
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ModelDownloadMemoryInfo(memoryAsync: deviceMemoryAsync),
                        ],
                      ),
                    ),
                    Actor(
                      delay: 60.ms,
                      acts: [.fadeIn(), .slideY(from: 0.08)],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: models.map((model) {
                          final isDownloaded = downloadedModelsAsync.when(
                            data: (set) => set.contains(model.id),
                            loading: () => false,
                            error: (_, _) => false,
                          );
                          final progressInfo = downloadStates[model.id];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ModelDownloadCard(
                              model: model,
                              isDownloaded: isDownloaded,
                              progressInfo: progressInfo,
                              theme: theme,
                              deviceMemory: deviceMemoryAsync.value,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Actor(
                delay: 120.ms,
                acts: [.fadeIn(), .slideY(from: 0.08)],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isCreatingServer)
                        const Center(child: CircularProgressIndicator())
                      else
                        ShadButton(
                          width: double.infinity,
                          onPressed: _canContinue()
                              ? _createOnDeviceServer
                              : null,
                          child: Text(
                            l10n.continue_action,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canContinue() {
    final downloadedSet = ref.read(downloadedModelsProvider).whenData((s) => s);
    return downloadedSet.hasValue && downloadedSet.value!.isNotEmpty;
  }

  Future<void> _createOnDeviceServer() async {
    setState(() => _isCreatingServer = true);

    try {
      final server = Server(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'On-Device',
        type: ServerType.onDevice,
        host: '',
        port: 0,
        isDefault: true,
        createdAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
        status: ConnectionStatus.connected,
        iconName: 'strokeRoundedSmartPhone01',
      );

      await ref.read(serversProvider.notifier).addServer(server);
      await ref.read(serversProvider.notifier).setDefault(server.id);
      ref.read(activeServerProvider.notifier).setActiveServer(server);

      if (mounted) {
        context.push(AppRoutes.onboardingTheme);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.error_with_message(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingServer = false);
      }
    }
  }
}
