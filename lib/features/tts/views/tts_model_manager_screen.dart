import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import '../../settings/data/models/app_settings.dart';
import '../../sidebar/sidebar_widget.dart';
import '../data/kitten_tts_model.dart';
import '../data/kokoro_tts_model.dart';
import '../providers/tts_model_providers.dart';
import '../providers/tts_providers.dart' as tts;

/// Async provider for the set of installed engine IDs.
final installedEnginesProvider = FutureProvider<Set<EngineId>>((ref) async {
  final downloader = ref.read(modelDownloaderProvider);
  final kittenDownloader = ref.read(kittenTtsDownloaderProvider);
  final kokoroDownloader = ref.read(kokoroTtsDownloaderProvider);
  final result = <EngineId>{};
  result.add(EngineId.system);
  final downloadedVariants = await kittenDownloader.getDownloadedVariants();
  if (downloadedVariants.isNotEmpty) {
    result.add(EngineId.kitten);
  }
  final downloadedKokoroVariants = await kokoroDownloader.getDownloadedVariants();
  if (downloadedKokoroVariants.isNotEmpty) {
    result.add(EngineId.kokoro);
  }
  if (await downloader.isEngineDownloaded(EngineId.piper)) {
    result.add(EngineId.piper);
  }
  return result;
});

class TtsModelManagerScreen extends ConsumerWidget {
  const TtsModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      drawer: const SidebarWidget(),
      appBar: AppBar(title: const Text('TTS Models')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SystemEngineCard(isSelected: settings.ttsEngine == EngineId.system),
          const SizedBox(height: 16),
          _KittenEngineCard(isSelected: settings.ttsEngine == EngineId.kitten),
          const SizedBox(height: 16),
          _KokoroEngineCard(isSelected: settings.ttsEngine == EngineId.kokoro),
          const SizedBox(height: 16),
          _PiperEngineCard(isSelected: settings.ttsEngine == EngineId.piper),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── System Engine ──

class _SystemEngineCard extends ConsumerWidget {
  final bool isSelected;

  const _SystemEngineCard({required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = EngineMeta.system;

    return _EngineCard(
      isSelected: isSelected,
      meta: meta,
      engine: EngineId.system,
      installed: true,
      statusText: 'Always available',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSelected)
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .setTtsEngine(EngineId.system),
              child: const Text('Select'),
            ),
        ],
      ),
      child: _SystemVoicesList(),
    );
  }
}

class _SystemVoicesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'Uses your device\'s built-in text-to-speech engine.\n'
        'No downloads required. Voice selection uses your device\'s system settings.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

// ── Kitten Engine ──

class _KittenEngineCard extends ConsumerWidget {
  final bool isSelected;

  const _KittenEngineCard({required this.isSelected});

  KittenTtsModel _selectedModel(AppSettings settings) {
    final variant = settings.kittenTtsModelVariant;
    return KittenTtsModel.allModels.firstWhere((m) => m.variant == variant);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final meta = EngineMeta.kitten;
    final downloadedAsync = ref.watch(downloadedKittenTtsVariantsProvider);
    final downloadProgress = ref.watch(ttsDownloadProgressProvider);
    final model = _selectedModel(settings);
    final variantProgress = downloadProgress[model.variant];
    final isInstalled = downloadedAsync.when(
      data: (set) => set.contains(model.variant),
      loading: () => false,
      error: (_, _) => false,
    );
    final notifier = ref.read(ttsDownloadProgressProvider.notifier);
    final isDownloading = notifier.isDownloading(model.variant);

    return _EngineCard(
      isSelected: isSelected,
      meta: meta,
      engine: EngineId.kitten,
      installed: isInstalled,
      statusText: isInstalled
          ? 'Installed'
          : isDownloading
          ? 'Downloading...'
          : 'Not installed',
      trailing: _buildAction(ref, isInstalled, isDownloading, model),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Lightning-fast neural TTS with 8 expressive voices.\n'
              'Requires ${_formatSize(model.totalSizeBytes)} download.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (isDownloading) ...[
            const SizedBox(height: 12),
            _buildVariantDownloadProgress(context, ref, model, variantProgress),
          ],
          if (isInstalled) ...[
            _VoiceChips(voices: kittenVoices, engine: EngineId.kitten),
          ],
        ],
      ),
    );
  }

  Widget _buildAction(
    WidgetRef ref,
    bool isInstalled,
    bool isDownloading,
    KittenTtsModel model,
  ) {
    final notifier = ref.read(ttsDownloadProgressProvider.notifier);
    if (isDownloading) {
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () => notifier.cancelDownload(model.variant),
        child: const Text('Cancel'),
      );
    }
    if (isInstalled) {
      if (isSelected) return const SizedBox.shrink();
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () =>
            ref.read(settingsProvider.notifier).setTtsEngine(EngineId.kitten),
        child: const Text('Select'),
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: () => notifier.startDownload(model),
      child: const Text('Install'),
    );
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  Widget _buildVariantDownloadProgress(
    BuildContext context,
    WidgetRef ref,
    KittenTtsModel model,
    Map<String, KittenTtsFileProgress>? progress,
  ) {
    final fraction = ref
        .read(ttsDownloadProgressProvider.notifier)
        .getOverallFraction(model.variant);
    return Column(
      children: [
        LinearProgressIndicator(value: fraction),
        const SizedBox(height: 4),
        if (progress != null)
          ...progress.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Text(
                    '${(e.value.fraction * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Kokoro Engine ──

class _KokoroEngineCard extends ConsumerWidget {
  final bool isSelected;

  const _KokoroEngineCard({required this.isSelected});

  KokoroTtsModel _selectedModel(AppSettings settings) {
    final variant = settings.kokoroTtsModelVariant;
    return KokoroTtsModel.forVariant(variant);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final meta = EngineMeta.kokoro;
    final downloadedAsync = ref.watch(downloadedKokoroTtsVariantsProvider);
    final downloadProgress = ref.watch(kokoroTtsDownloadProgressProvider);
    final model = _selectedModel(settings);
    final variantProgress = downloadProgress[model.variant];
    final isInstalled = downloadedAsync.when(
      data: (set) => set.contains(model.variant),
      loading: () => false,
      error: (_, _) => false,
    );
    final notifier = ref.read(kokoroTtsDownloadProgressProvider.notifier);
    final isDownloading = notifier.isDownloading(model.variant);

    return _EngineCard(
      isSelected: isSelected,
      meta: meta,
      engine: EngineId.kokoro,
      installed: isInstalled,
      statusText: isInstalled
          ? 'Installed'
          : isDownloading
          ? 'Downloading...'
          : 'Not installed',
      trailing: _buildAction(ref, isInstalled, isDownloading, model),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Kokoro 82M parameter model with 22 expressive voices.\n'
              'Requires ${_formatSize(model.totalSizeBytes)} download.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ),
          if (isDownloading) ...[
            const SizedBox(height: 12),
            _buildVariantDownloadProgress(
              context,
              ref,
              model,
              variantProgress,
            ),
          ],
          if (isInstalled) ...[
            _VoiceChips(voices: kokoroVoices, engine: EngineId.kokoro),
          ],
        ],
      ),
    );
  }

  Widget _buildAction(
    WidgetRef ref,
    bool isInstalled,
    bool isDownloading,
    KokoroTtsModel model,
  ) {
    final notifier = ref.read(kokoroTtsDownloadProgressProvider.notifier);
    if (isDownloading) {
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () => notifier.cancelDownload(model.variant),
        child: const Text('Cancel'),
      );
    }
    if (isInstalled) {
      if (isSelected) return const SizedBox.shrink();
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () =>
            ref.read(settingsProvider.notifier).setTtsEngine(EngineId.kokoro),
        child: const Text('Select'),
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: () => notifier.startDownload(model.variant),
      child: const Text('Install'),
    );
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  Widget _buildVariantDownloadProgress(
    BuildContext context,
    WidgetRef ref,
    KokoroTtsModel model,
    Map<String, KokoroTtsFileProgress>? progress,
  ) {
    final fraction = ref
        .read(kokoroTtsDownloadProgressProvider.notifier)
        .getOverallFraction(model.variant);
    return Column(
      children: [
        LinearProgressIndicator(value: fraction),
        const SizedBox(height: 4),
        if (progress != null)
          ...progress.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Text(
                    '${(e.value.fraction * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Piper Engine ──

class _PiperEngineCard extends ConsumerWidget {
  final bool isSelected;

  const _PiperEngineCard({required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = EngineMeta(
      name: 'Piper TTS',
      tagline: 'Open-source neural voices',
      sizeMb: 50,
      ramMb: 100,
      voiceCount: 100,
      accentColor: 0xFF4CAF50,
    );
    final installedAsync = ref.watch(installedEnginesProvider);
    final isInstalled = installedAsync.when(
      data: (set) => set.contains(EngineId.piper),
      loading: () => false,
      error: (_, _) => false,
    );

    return _EngineCard(
      isSelected: isSelected,
      meta: meta,
      engine: EngineId.piper,
      installed: isInstalled,
      statusText: isInstalled ? 'Installed' : 'Not installed',
      trailing: isInstalled && !isSelected
          ? ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .setTtsEngine(EngineId.piper),
              child: const Text('Select'),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'One ONNX model per voice. 30+ languages, hundreds of voices.\n'
          'Place model files in the tts_models/piper directory.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ──

class _EngineCard extends StatelessWidget {
  final bool isSelected;
  final EngineMeta meta;
  final EngineId engine;
  final bool installed;
  final String statusText;
  final Widget? trailing;
  final Widget? child;

  const _EngineCard({
    required this.isSelected,
    required this.meta,
    required this.engine,
    required this.installed,
    required this.statusText,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = Color(meta.accentColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? accentColor.withValues(alpha: 0.6)
              : installed
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.record_voice_over,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      meta.tagline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: installed
                          ? Colors.green
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${meta.sizeMb} MB · ${meta.ramMb} MB RAM · ${meta.voiceCount} voices',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              ?trailing,
            ],
          ),
          ?child,
        ],
      ),
    );
  }
}

class _VoiceChips extends ConsumerStatefulWidget {
  final List<Voice> voices;
  final EngineId engine;

  const _VoiceChips({required this.voices, required this.engine});

  @override
  ConsumerState<_VoiceChips> createState() => _VoiceChipsState();
}

class _VoiceChipsState extends ConsumerState<_VoiceChips> {
  Voice? _playingVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final selectedVoiceId = widget.engine == settings.ttsEngine
        ? settings.ttsVoiceId
        : null;
    final females = widget.voices.where((v) => v.gender == 'f').toList();
    final males = widget.voices.where((v) => v.gender == 'm').toList();
    final accent = Color(EngineMeta.forEngine(widget.engine).accentColor);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (females.isNotEmpty) ...[
            Text(
              'Female',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: females
                  .map((v) => _voiceChip(v, theme, accent, selectedVoiceId))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (males.isNotEmpty) ...[
            Text(
              'Male',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: males
                  .map((v) => _voiceChip(v, theme, accent, selectedVoiceId))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _voiceChip(
    Voice voice,
    ThemeData theme,
    Color accent,
    String? selectedVoiceId,
  ) {
    final isPlaying = _playingVoice == voice;
    final isSelected = voice.id == selectedVoiceId && !isPlaying;

    return ActionChip(
      avatar: Icon(
        isSelected
            ? Icons.check_circle
            : isPlaying
            ? Icons.stop
            : Icons.play_arrow,
        size: 16,
        color: isSelected
            ? Colors.green
            : isPlaying
            ? accent
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      label: Text(voice.name),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: isSelected
            ? Colors.green
            : isPlaying
            ? accent
            : theme.colorScheme.onSurface,
        fontWeight: isSelected || isPlaying
            ? FontWeight.bold
            : FontWeight.normal,
      ),
      backgroundColor: isSelected
          ? Colors.green.withValues(alpha: 0.1)
          : isPlaying
          ? accent.withValues(alpha: 0.1)
          : Colors.transparent,
      side: BorderSide(
        color: isSelected
            ? Colors.green.withValues(alpha: 0.5)
            : isPlaying
            ? accent.withValues(alpha: 0.3)
            : theme.colorScheme.outline.withValues(alpha: 0.2),
      ),
      onPressed: () => _selectAndPreview(voice),
    );
  }

  Future<void> _selectAndPreview(Voice voice) async {
    // Set as default voice for this engine
    ref.read(settingsProvider.notifier).setTtsVoiceId(voice.id);

    // Preview the voice
    if (_playingVoice == voice) {
      await ref.read(tts.ttsProvider.notifier).stop();
      if (mounted) setState(() => _playingVoice = null);
      return;
    }
    try {
      await ref.read(tts.ttsProvider.notifier).previewVoice(voice);
      if (mounted) setState(() => _playingVoice = voice);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _playingVoice = null);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
      }
    }
  }
}
