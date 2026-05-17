import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';

class BackendSelector extends ConsumerWidget {
  const BackendSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final currentBackend = settings.preferredBackend;
    final isAndroid = Platform.isAndroid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inference_backend,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (!isAndroid)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.backend_ios_notice,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ...LiteLmBackendType.values.map((backend) {
          final isAvailable = isAndroid || backend == LiteLmBackendType.cpu;
          final isSelected = currentBackend == backend;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Opacity(
              opacity: isAvailable ? 1.0 : 0.4,
              child: ShadButton.outline(
                width: double.infinity,
                onPressed: isAvailable
                    ? () => ref
                          .read(settingsProvider.notifier)
                          .setPreferredBackend(backend)
                    : null,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            backend.name.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _backendDescription(backend, context),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _backendDescription(LiteLmBackendType backend, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (backend) {
      case LiteLmBackendType.cpu:
        return l10n.backend_cpu_desc;
      case LiteLmBackendType.gpu:
        return l10n.backend_gpu_desc;
      case LiteLmBackendType.npu:
        return l10n.backend_npu_desc;
    }
  }
}
