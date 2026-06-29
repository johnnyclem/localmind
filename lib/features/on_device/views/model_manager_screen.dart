import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/providers/app_providers.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:localmind/features/on_device/data/models/on_device_model.dart';
import 'package:localmind/features/on_device/providers/foreground_download_providers.dart';
import 'package:localmind/features/on_device/providers/on_device_providers.dart';
import 'package:localmind/features/on_device/components/memory_stats_panel.dart';
import 'package:localmind/features/on_device/components/model_card.dart';
import 'package:url_launcher/url_launcher.dart';

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
                title: 'Imported GGUF models',
                subtitle: importedModels.isEmpty
                    ? 'Import a GGUF from your device or add one from Hugging Face. Imported models run locally with llama.cpp.'
                    : '${importedModels.length} imported model${importedModels.length == 1 ? '' : 's'} ready for local inference.',
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
                subtitle:
                    'Curated on-device models you can download and manage inside LocalMind.',
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

      final model = await ref
          .read(importedGgufModelsProvider.notifier)
          .importModel(path);
      messenger.showSnackBar(
        SnackBar(content: Text('${model.name} imported from local file.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to import GGUF model: $e')),
      );
    }
  }

  Future<void> _importFromHuggingFace(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final importedModel = await showDialog<OnDeviceModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _HuggingFaceGgufImportDialog(),
    );

    if (!mounted || importedModel == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${importedModel.name} imported from Hugging Face.'),
      ),
    );
  }
}

class _ManagerHeader extends StatelessWidget {
  const _ManagerHeader({
    required this.l10n,
    required this.theme,
    required this.onImportLocalGguf,
    required this.onImportFromHuggingFace,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onImportLocalGguf;
  final VoidCallback onImportFromHuggingFace;

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
            PopupMenuButton<_ImportAction>(
              tooltip: 'Import GGUF',
              onSelected: (value) {
                switch (value) {
                  case _ImportAction.localFile:
                    onImportLocalGguf();
                  case _ImportAction.huggingFace:
                    onImportFromHuggingFace();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<_ImportAction>(
                  value: _ImportAction.localFile,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.folder_open_outlined),
                    title: Text('Import local GGUF'),
                    subtitle: Text('Copy a .gguf file from this device'),
                  ),
                ),
                PopupMenuItem<_ImportAction>(
                  value: _ImportAction.huggingFace,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.cloud_download_outlined),
                    title: Text('Import from Hugging Face'),
                    subtitle: Text('Paste a GGUF URL or repo path'),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Import GGUF'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportOverviewCard extends StatelessWidget {
  const _ImportOverviewCard({
    required this.importedModels,
    required this.onImportLocalGguf,
    required this.onImportFromHuggingFace,
  });

  final List<OnDeviceModel> importedModels;
  final VoidCallback onImportLocalGguf;
  final VoidCallback onImportFromHuggingFace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localImports = importedModels
        .where((model) => model.isImportedFromLocalFile)
        .length;
    final huggingFaceImports = importedModels
        .where((model) => model.isImportedFromHuggingFace)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.memory_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bring your own GGUF models',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Import a .gguf from local storage or download one straight from Hugging Face. Imported models stay on this device and load with llama.cpp.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                icon: Icons.layers_outlined,
                label: '${importedModels.length} imported',
              ),
              _SummaryPill(
                icon: Icons.folder_open_outlined,
                label: '$localImports local files',
              ),
              _SummaryPill(
                icon: Icons.cloud_download_outlined,
                label: '$huggingFaceImports Hugging Face',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onImportLocalGguf,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Import local GGUF'),
              ),
              OutlinedButton.icon(
                onPressed: onImportFromHuggingFace,
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Import from Hugging Face'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyImportedModelsCard extends StatelessWidget {
  const _EmptyImportedModelsCard({
    required this.onImportLocalGguf,
    required this.onImportFromHuggingFace,
  });

  final VoidCallback onImportLocalGguf;
  final VoidCallback onImportFromHuggingFace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No imported GGUF models yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You can bring your own GGUF file from device storage or paste a Hugging Face URL or repo path that points to a .gguf file.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onImportLocalGguf,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Import local GGUF'),
              ),
              OutlinedButton.icon(
                onPressed: onImportFromHuggingFace,
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Import from Hugging Face'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HuggingFaceGgufImportDialog extends ConsumerStatefulWidget {
  const _HuggingFaceGgufImportDialog();

  @override
  ConsumerState<_HuggingFaceGgufImportDialog> createState() =>
      _HuggingFaceGgufImportDialogState();
}

class _HuggingFaceGgufImportDialogState
    extends ConsumerState<_HuggingFaceGgufImportDialog> {
  static final Uri _huggingFaceModelsUri = Uri.parse(
    'https://huggingface.co/models?search=gguf',
  );

  final TextEditingController _urlController = TextEditingController();
  CancelToken? _cancelToken;
  bool _isImporting = false;
  String? _error;
  int _receivedBytes = 0;
  int _totalBytes = 0;

  @override
  void dispose() {
    _cancelToken?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasHuggingFaceToken = ref.watch(
      settingsProvider.select(
        (settings) => settings.huggingFaceToken?.trim().isNotEmpty == true,
      ),
    );
    final input = _urlController.text.trim();
    final preview = _ImportUrlPreview.fromInput(input);
    final progress = _totalBytes > 0 ? _receivedBytes / _totalBytes : null;
    final dialogWidth = MediaQuery.of(context).size.width > 560
        ? 520.0
        : MediaQuery.of(context).size.width * 0.82;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.cloud_download_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Import GGUF from Hugging Face')),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste a direct GGUF URL or a Hugging Face repo path like `owner/repo/blob/main/model.gguf`. Blob links are converted automatically.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _urlController,
                enabled: !_isImporting,
                maxLines: 2,
                minLines: 1,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_error != null) {
                    setState(() => _error = null);
                  } else {
                    setState(() {});
                  }
                },
                onSubmitted: (_) {
                  if (!_isImporting) {
                    _startImport();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'GGUF URL or repo path',
                  hintText:
                      'owner/repo/blob/main/model.gguf\nhttps://huggingface.co/owner/repo/resolve/main/model.gguf',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isImporting ? null : _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: const Text('Paste'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isImporting || input.isEmpty
                        ? null
                        : _clearInput,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isImporting
                        ? null
                        : () => _openHuggingFace(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Browse GGUFs'),
                  ),
                ],
              ),
              if (preview != null) ...[
                const SizedBox(height: 14),
                _ImportPreviewCard(preview: preview),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      hasHuggingFaceToken
                          ? Icons.verified_user_outlined
                          : Icons.info_outline,
                      size: 18,
                      color: hasHuggingFaceToken
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasHuggingFaceToken
                                ? 'Hugging Face token ready'
                                : 'Token optional but recommended',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasHuggingFaceToken
                                ? 'Your saved token will be used automatically for gated or private repositories.'
                                : '${l10n.model_requires_huggingface_token} Add one in Settings if this GGUF is gated or private.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isImporting) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview?.fileName ?? 'Downloading GGUF',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              progress == null
                                  ? 'Preparing'
                                  : '${(progress * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ImportProgressBar(progress: progress),
                      const SizedBox(height: 10),
                      Text(
                        progress != null
                            ? '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)}'
                            : 'Preparing download...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.70,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting
              ? () {
                  _cancelToken?.cancel();
                  Navigator.of(context).pop();
                }
              : () => Navigator.of(context).pop(),
          child: Text(_isImporting ? 'Cancel import' : l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _isImporting || input.isEmpty ? null : _startImport,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Import GGUF'),
        ),
      ],
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard is empty.')));
      return;
    }
    setState(() {
      _urlController.text = text;
      _error = null;
    });
  }

  void _clearInput() {
    setState(() {
      _urlController.clear();
      _error = null;
    });
  }

  Future<void> _openHuggingFace(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(
      _huggingFaceModelsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open Hugging Face.')),
      );
    }
  }

  Future<void> _startImport() async {
    final sourceUrl = _urlController.text.trim();
    if (sourceUrl.isEmpty) {
      setState(() {
        _error = 'Paste a Hugging Face GGUF URL or repo path.';
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _error = null;
      _receivedBytes = 0;
      _totalBytes = 0;
    });

    _cancelToken = CancelToken();

    try {
      final huggingFaceToken = ref.read(
        settingsProvider.select((settings) => settings.huggingFaceToken),
      );
      final model = await ref
          .read(importedGgufModelsProvider.notifier)
          .importModelFromHuggingFaceUrl(
            sourceUrl,
            huggingFaceToken: huggingFaceToken,
            cancelToken: _cancelToken,
            onProgress: (receivedBytes, totalBytes) {
              if (!mounted) return;
              setState(() {
                _receivedBytes = receivedBytes;
                _totalBytes = totalBytes > 0 ? totalBytes : 0;
              });
            },
          );

      if (!mounted) return;
      Navigator.of(context).pop(model);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.startsWith('HttpException: ')) {
      return message.substring('HttpException: '.length);
    }
    if (message.startsWith('FormatException: ')) {
      return message.substring('FormatException: '.length);
    }
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}

class _ImportPreviewCard extends StatelessWidget {
  const _ImportPreviewCard({required this.preview});

  final _ImportUrlPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewPill(
                icon: preview.isBlobLink
                    ? Icons.sync_alt_rounded
                    : Icons.link_rounded,
                label: preview.isBlobLink
                    ? 'Blob link'
                    : preview.inputStyleLabel,
              ),
              if (preview.fileName != null)
                _PreviewPill(
                  icon: Icons.insert_drive_file_outlined,
                  label: preview.fileName!,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (preview.repoPath != null)
            _PreviewRow(label: 'Repository', value: preview.repoPath!),
          if (preview.normalizedDisplay != null)
            _PreviewRow(
              label: 'Detected path',
              value: preview.normalizedDisplay!,
            ),
        ],
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportProgressBar extends StatelessWidget {
  const _ImportProgressBar({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackColor = theme.colorScheme.primary.withValues(alpha: 0.12);
    final fillColor = theme.colorScheme.primary;
    final normalizedProgress = progress?.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: normalizedProgress?.toDouble(),
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      ),
    );
  }
}

class _ImportUrlPreview {
  const _ImportUrlPreview({
    required this.inputStyleLabel,
    required this.isBlobLink,
    this.repoPath,
    this.fileName,
    this.normalizedDisplay,
  });

  final String inputStyleLabel;
  final bool isBlobLink;
  final String? repoPath;
  final String? fileName;
  final String? normalizedDisplay;

  static _ImportUrlPreview? fromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final hasScheme =
        trimmed.startsWith('https://') || trimmed.startsWith('http://');
    final displayUri = hasScheme ? Uri.tryParse(trimmed) : null;
    final pathSource = displayUri != null && displayUri.pathSegments.isNotEmpty
        ? displayUri.pathSegments
        : trimmed.split('/').where((part) => part.isNotEmpty).toList();

    if (pathSource.isEmpty) {
      return const _ImportUrlPreview(
        inputStyleLabel: 'Manual path',
        isBlobLink: false,
      );
    }

    final blobIndex = pathSource.indexOf('blob');
    final resolveIndex = pathSource.indexOf('resolve');
    final fileName =
        pathSource.isNotEmpty && pathSource.last.toLowerCase().endsWith('.gguf')
        ? pathSource.last
        : null;
    final repoPath = pathSource.length >= 2
        ? '${pathSource[0]}/${pathSource[1]}'
        : null;

    String? normalizedDisplay;
    if (blobIndex != -1) {
      final normalized = [...pathSource]..[blobIndex] = 'resolve';
      normalizedDisplay = normalized.join('/');
    } else if (resolveIndex != -1 || fileName != null) {
      normalizedDisplay = pathSource.join('/');
    }

    return _ImportUrlPreview(
      inputStyleLabel: hasScheme ? 'Direct URL' : 'Repo path',
      isBlobLink: blobIndex != -1,
      repoPath: repoPath,
      fileName: fileName,
      normalizedDisplay: normalizedDisplay,
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
          : models.where((m) => m.id == loadedId).map((m) => m.name).followedBy(
              [loadedId],
            ).first;

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
                l10n.model_loaded(
                  loadedName,
                  engineState.backend?.name ?? 'CPU',
                ),
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
