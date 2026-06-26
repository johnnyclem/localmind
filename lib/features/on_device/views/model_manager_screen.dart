import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:localmind/features/on_device/data/models/on_device_model.dart';
import 'package:localmind/features/on_device/providers/on_device_providers.dart';
import 'package:localmind/features/on_device/providers/foreground_download_providers.dart';
import 'package:localmind/features/on_device/components/memory_stats_panel.dart';
import 'package:localmind/features/on_device/components/model_card.dart';

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

    return Column(
      children: [
        _ManagerHeader(
          l10n: l10n,
          theme: theme,
          onImportGguf: () => _importGguf(context, ref),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const MemoryStatsPanel(),
              _EngineStatusCard(
                engineState: engineState,
                models: models,
                l10n: l10n,
                theme: theme,
              ),
              Text(
                l10n.available_models,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...models.map(
                (model) => ModelCard(
                  model: model,
                  downloadedAsync: downloadedAsync,
                  downloadProgress: downloadProgress[model.id],
                  engineState: engineState,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _importGguf(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gguf'],
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null || !path.toLowerCase().endsWith('.gguf')) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Only GGUF models are supported for this import.'),
          ),
        );
        return;
      }

      await ref.read(importedGgufModelsProvider.notifier).importModel(path);
      messenger.showSnackBar(
        const SnackBar(content: Text('GGUF model imported.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to import GGUF model: $e')),
      );
    }
  }
}

class _ManagerHeader extends StatelessWidget {
  const _ManagerHeader({
    required this.l10n,
    required this.theme,
    required this.onImportGguf,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onImportGguf;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: topPadding + 8,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0A0A0A)
            : const Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.on_device_models_title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          if (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: onImportGguf,
              child: const Text('Import GGUF'),
            ),
        ],
      ),
    );
  }
}

class _EngineStatusCard extends StatelessWidget {
  const _EngineStatusCard({
    required this.engineState,
    required this.models,
    required this.l10n,
    required this.theme,
  });

  final OnDeviceEngineState engineState;
  final List<OnDeviceModel> models;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (engineState.status == OnDeviceEngineStatus.loaded) {
      final loadedId = engineState.loadedModelId;
      final loadedName = loadedId == null
          ? 'Unknown'
          : models
                .where((m) => m.id == loadedId)
                .map((m) => m.name)
                .followedBy([loadedId])
                .first;

      return Container(
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
                l10n.model_loaded(loadedName, engineState.backend?.name ?? 'CPU'),
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    if (engineState.status == OnDeviceEngineStatus.loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      );
    }

    if (engineState.status == OnDeviceEngineStatus.error) {
      return Container(
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
      );
    }

    return const SizedBox.shrink();
  }
}
