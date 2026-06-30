import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/providers/app_providers.dart';
import 'package:localmind/core/providers/foreground_download_providers.dart';
import 'package:localmind/core/providers/on_device_providers.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:localmind/features/on_device/data/models/on_device_model.dart';
import 'package:localmind/features/on_device/views/components/memory_stats_panel.dart';
import 'package:localmind/features/on_device/views/components/model_card.dart';
import 'package:url_launcher/url_launcher.dart';

part 'model_manager_screen_parts.dart';

enum _ImportAction { localFile, huggingFace }

class OnDeviceModelManagerScreen extends ConsumerStatefulWidget {
  const OnDeviceModelManagerScreen({super.key});

  @override
  ConsumerState<OnDeviceModelManagerScreen> createState() =>
      _OnDeviceModelManagerScreenState();
}

class _OnDeviceModelManagerScreenState
    extends ConsumerState<OnDeviceModelManagerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(importedGgufModelsProvider.notifier).pruneMissing(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final models = ref.watch(onDeviceModelsProvider);
    final downloadedAsync = ref.watch(downloadedModelsProvider);
    final engineState = ref.watch(onDeviceEngineProvider);
    final downloadProgress = ref.watch(foregroundDownloadNotifierProvider);

    final importedModels = models.where((model) => model.isImported).toList()
      ..sort(
        (a, b) => (b.importedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.importedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    final curatedModels = models.where((model) => !model.isImported).toList();

    return Column(
      children: [
        _ManagerHeader(
          l10n: l10n,
          theme: theme,
          onImportLocalGguf: () => _importLocalGguf(context),
          onImportFromHuggingFace: () => _importFromHuggingFace(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const MemoryStatsPanel(),
              _ImportOverviewCard(
                importedModels: importedModels,
                onImportLocalGguf: () => _importLocalGguf(context),
                onImportFromHuggingFace: () => _importFromHuggingFace(context),
              ),
              _EngineStatusCard(
                engineState: engineState,
                models: models,
                l10n: l10n,
                theme: theme,
              ),
              const SizedBox(height: 4),
              _SectionHeader(
                title: l10n.gguf_imported_models_title,
                subtitle: importedModels.isEmpty
                    ? l10n.gguf_imported_models_empty_subtitle
                    : '${importedModels.length} ${l10n.gguf_imported_models_ready}',
              ),
              if (importedModels.isEmpty)
                _EmptyImportedModelsCard(
                  onImportLocalGguf: () => _importLocalGguf(context),
                  onImportFromHuggingFace: () =>
                      _importFromHuggingFace(context),
                )
              else
                ...importedModels.map(
                  (model) => ModelCard(
                    model: model,
                    downloadedAsync: downloadedAsync,
                    downloadProgress: downloadProgress[model.id],
                    engineState: engineState,
                  ),
                ),
              const SizedBox(height: 8),
              _SectionHeader(
                title: l10n.available_models,
                subtitle: l10n.gguf_curated_models_subtitle,
              ),
              const SizedBox(height: 4),
              ...curatedModels.map(
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

  Future<void> _importLocalGguf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gguf'],
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null || !path.toLowerCase().endsWith('.gguf')) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.gguf_only_supported)),
        );
        return;
      }

      final model = await ref
          .read(importedGgufModelsProvider.notifier)
          .importModel(path);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${model.name} ${l10n.gguf_imported_from_local_file}'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.gguf_import_failed}: ${_friendlyErrorForL10n(l10n, e)}',
          ),
        ),
      );
    }
  }

  Future<void> _importFromHuggingFace(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final importedModel = await showDialog<OnDeviceModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _HuggingFaceGgufImportDialog(),
    );

    if (!mounted || importedModel == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${importedModel.name} ${l10n.gguf_imported_from_huggingface}',
        ),
      ),
    );
  }

  String _friendlyErrorForL10n(AppLocalizations l10n, Object error) {
    final message = error.toString();
    final normalized = message
        .replaceFirst('HttpException: ', '')
        .replaceFirst('FormatException: ', '')
        .replaceFirst('FileSystemException: ', '');

    switch (normalized) {
      case 'GGUF import canceled.':
        return l10n.gguf_import_canceled;
      case 'Enter a Hugging Face GGUF URL.':
        return l10n.gguf_enter_huggingface_url;
      case 'Only official Hugging Face GGUF URLs are supported.':
        return l10n.gguf_only_official_huggingface_urls;
      case 'Use an HTTPS Hugging Face URL for GGUF import.':
        return l10n.gguf_use_https_url;
      case 'The Hugging Face URL must point directly to a .gguf file.':
        return l10n.gguf_url_must_point_to_file;
      case 'Unable to determine the GGUF file name.':
        return l10n.gguf_unable_to_detect_file_name;
      case 'The downloaded GGUF file was empty or missing.':
        return l10n.gguf_download_empty;
      case 'Selected model file does not exist':
        return l10n.gguf_selected_file_missing;
      default:
        return normalized;
    }
  }
}
