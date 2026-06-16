import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../sidebar/sidebar_widget.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import '../../on_device/data/models/on_device_model.dart';
import '../../on_device/data/models/download_progress_info.dart';
import '../../on_device/data/models/download_status.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../../on_device/providers/foreground_download_providers.dart';
import '../../../core/providers/device_info_providers.dart';
import '../../../core/device/device_memory_service.dart';

class OnDeviceModelManagerScreen extends ConsumerWidget {
  const OnDeviceModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final models = ref.watch(onDeviceModelsProvider);
    final downloadedAsync = ref.watch(downloadedModelsProvider);
    final engineState = ref.watch(onDeviceEngineProvider);
    final downloadProgress = ref.watch(foregroundDownloadNotifierProvider);
    final deviceMemoryAsync = ref.watch(deviceMemoryProvider);

    ref.listen(onDeviceEngineProvider, (prev, next) {
      if (next.status == OnDeviceEngineStatus.loaded &&
          prev?.status == OnDeviceEngineStatus.loading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.model_loaded(
                next.loadedModelId ?? 'Unknown',
                next.backend?.name ?? 'CPU',
              ),
            ),
          ),
        );
      }
    });

    return Scaffold(
      drawer: const SidebarWidget(),
      appBar: AppBar(title: Text(l10n.on_device_models_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMemoryInfo(context, ref, deviceMemoryAsync),
          if (engineState.status == OnDeviceEngineStatus.loaded)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.model_loaded(
                        engineState.loadedModelId ?? 'Unknown',
                        engineState.backend?.name ?? 'CPU',
                      ),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            )
          else if (engineState.status == OnDeviceEngineStatus.loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(),
            )
          else if (engineState.status == OnDeviceEngineStatus.error)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                engineState.error ?? l10n.unknown_error,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Text(
            l10n.available_models,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...models.map(
            (model) => _ModelCard(
              model: model,
              theme: theme,
              downloadedAsync: downloadedAsync,
              downloadProgress: downloadProgress[model.id],
              engineState: engineState,
              deviceMemory: deviceMemoryAsync.value,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMemoryInfo(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<DeviceMemoryInfo> memoryAsync,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return memoryAsync.when(
      data: (info) {
        if (info.totalMemoryMb == 0) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final usedMb = info.totalMemoryMb - info.availableMemoryMb;
        final usagePercent = usedMb / info.totalMemoryMb;

        // Memory health logic
        Color statusColor = Colors.green;
        String statusText = l10n.memory_healthy;
        if (info.availableMemoryMb < 1024) {
          statusColor = Colors.red;
          statusText = l10n.memory_critical;
        } else if (info.availableMemoryMb < 2048) {
          statusColor = Colors.orange;
          statusText = l10n.memory_low;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 20,
                  top: 16,
                  end: 12,
                  bottom: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.memory_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.device_memory,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () => ref.invalidate(deviceMemoryProvider),
                      child: const Icon(Icons.refresh_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.ram_usage,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            width: double.infinity,
                            color: theme.colorScheme.surfaceContainerLowest,
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 10,
                            width:
                                MediaQuery.of(context).size.width *
                                usagePercent,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor,
                                  statusColor.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.ram_used(
                            (usagePercent * 100).toStringAsFixed(0),
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_formatMb(usedMb)} / ${info.totalMemoryFormatted}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MemoryStat(
                        label: l10n.available_ram,
                        value: info.availableMemoryFormatted,
                        icon: Icons.speed_rounded,
                        color: statusColor,
                        isPrimary: true,
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _MemoryStat(
                        label: l10n.total_capacity,
                        value: info.totalMemoryFormatted,
                        icon: Icons.storage_rounded,
                        alignment: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _formatMb(int mb) {
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '$mb MB';
  }
}

class _MemoryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final CrossAxisAlignment alignment;
  final bool isPrimary;

  const _MemoryStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.alignment = CrossAxisAlignment.start,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        color ?? theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignment == CrossAxisAlignment.start) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            if (alignment == CrossAxisAlignment.end) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 14, color: iconColor),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:
              (isPrimary
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: isPrimary ? -0.5 : null,
                  ),
        ),
      ],
    );
  }
}

class _ModelCard extends ConsumerWidget {
  const _ModelCard({
    required this.model,
    required this.theme,
    required this.downloadedAsync,
    required this.downloadProgress,
    required this.engineState,
    this.deviceMemory,
  });

  final OnDeviceModel model;
  final ThemeData theme;
  final AsyncValue<Set<String>> downloadedAsync;
  final DownloadProgressInfo? downloadProgress;
  final OnDeviceEngineState engineState;
  final DeviceMemoryInfo? deviceMemory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDownloaded = downloadedAsync.when(
      data: (set) => set.contains(model.id),
      loading: () => false,
      error: (_, _) => false,
    );

    final isLoading =
        engineState.status == OnDeviceEngineStatus.loading &&
        engineState.loadedModelId == model.id;

    final isDownloading =
        downloadProgress != null &&
        (downloadProgress!.status == DownloadStatus.running ||
            downloadProgress!.status == DownloadStatus.pending);

    final isPaused =
        downloadProgress?.status == DownloadStatus.paused ||
        downloadProgress?.status == DownloadStatus.canceled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDownloaded
                ? Colors.green.withValues(alpha: 0.5)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isDownloaded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (model.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.recommended,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (!Platform.isIOS &&
                deviceMemory != null &&
                deviceMemory!.isOversized(model.minRamMb))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.may_be_large,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              model.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            _buildCapabilityChips(),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  model.fileSizeFormatted,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(width: 12),
                Text(model.license, style: theme.textTheme.labelMedium),
                const SizedBox(width: 12),
                Text(
                  l10n.ram_min_required('${model.minRamMb ~/ 1024 + 1}'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildActionRow(
              context,
              ref,
              isDownloaded,
              isLoading,
              isDownloading,
              isPaused,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityChips() {
    final chips = <String>[
      if (model.supportsFunctionCalling) 'Tools',
      if (model.supportsThinking) 'Thinking',
      if (model.supportsVision) 'Vision',
      model.languagesLabel,
      if (model.backendNote != null) model.backendNote!,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips.map(_buildCapabilityChip).toList(),
    );
  }

  Widget _buildCapabilityChip(String label) {
    final isBackendNote = label == model.backendNote;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isBackendNote ? Colors.orange : theme.colorScheme.primary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isBackendNote ? Colors.orange : theme.colorScheme.primary)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isBackendNote ? Colors.orange : theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    WidgetRef ref,
    bool isDownloaded,
    bool isLoading,
    bool isDownloading,
    bool isPaused,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isLoaded = engineState.loadedModelId == model.id;

    if (isDownloaded) {
      return Row(
        children: [
          Icon(
            isLoaded ? Icons.check_circle : Icons.check_circle_outline,
            color: isLoaded ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            isLoaded ? l10n.loaded_status : l10n.downloaded,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLoaded ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isLoaded)
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: () => _unloadModel(ref),
              child: Text(l10n.unload),
            )
          else
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: () => _loadModel(context, ref),
              child: Text(l10n.load),
            ),
          const SizedBox(width: 8),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () => _deleteModel(context, ref),
            child: Text(l10n.delete),
          ),
        ],
      );
    }

    if (isDownloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: downloadProgress?.progress ?? 0.0,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.download_progress(
                            ((downloadProgress?.progress ?? 0) * 100)
                                .toStringAsFixed(1),
                            downloadProgress?.speedFormatted ?? '0 B/s',
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.eta_label(
                            downloadProgress?.etaFormatted ?? l10n.calculating,
                          ),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      downloadProgress?.progressFormatted ?? '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: () => ref
                    .read(foregroundDownloadNotifierProvider.notifier)
                    .cancelDownload(model.id),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ],
      );
    }

    if (downloadProgress?.status == DownloadStatus.failed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              downloadProgress?.error ?? l10n.download_failed,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () => ref
                .read(foregroundDownloadNotifierProvider.notifier)
                .retryDownload(model.id),
            child: Text(l10n.retry),
          ),
        ],
      );
    }

    if (isPaused) {
      return Row(
        children: [
          Text(
            l10n.paused_progress(
              ((downloadProgress?.progress ?? 0) * 100).toStringAsFixed(0),
            ),
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: () => _startDownload(context, ref),
            child: Text(l10n.resume),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Spacer(),
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: () => _startDownload(context, ref),
          child: Text(l10n.download),
        ),
      ],
    );
  }

  Future<void> _startDownload(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    if (!Platform.isIOS && deviceMemory != null) {
      if (deviceMemory!.isOversized(model.minRamMb)) {
        final proceed = await _showRamWarning(
          context,
          l10n.ram_warning_body_download(
            '${model.minRamMb ~/ 1024 + 1}',
            deviceMemory!.totalMemoryFormatted,
          ),
        );
        if (!proceed) return;
      }
    }

    await ref
        .read(foregroundDownloadNotifierProvider.notifier)
        .startDownload(model.id);
  }

  Future<void> _loadModel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    if (!Platform.isIOS && deviceMemory != null) {
      if (!deviceMemory!.hasEnoughRam(model.minRamMb)) {
        final proceed = await _showRamWarning(
          context,
          l10n.ram_warning_body_load(
            deviceMemory!.availableMemoryFormatted,
            '${model.minRamMb ~/ 1024 + 1}',
          ),
        );
        if (!proceed) return;
      }
    }

    final settings = ref.read(settingsProvider);
    final engineNotifier = ref.read(onDeviceEngineProvider.notifier);
    await engineNotifier.loadModel(model.id, settings.preferredBackend);
  }

  Future<bool> _showRamWarning(BuildContext context, String message) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.ram_warning),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(l10n.proceed_anyway),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _unloadModel(WidgetRef ref) async {
    await ref.read(onDeviceEngineProvider.notifier).unloadModel();
  }

  Future<void> _deleteModel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete_model_title),
        content: Text(l10n.delete_model_body(model.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final engineState = ref.read(onDeviceEngineProvider);
      if (engineState.loadedModelId == model.id) {
        await ref.read(onDeviceEngineProvider.notifier).unloadModel();
      }

      final gemmaService = ref.read(onDeviceGemmaServiceProvider);
      await gemmaService.deleteModel(model.id);
      ref.invalidate(downloadedModelsProvider);
    }
  }
}
