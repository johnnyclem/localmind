import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neural_tts/neural_tts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/providers/app_providers.dart';
import '../../sidebar/sidebar_widget.dart';
import '../providers/tts_model_providers.dart';
import '../providers/tts_providers.dart' as tts;

/// Async provider for the set of installed engine IDs.
final installedEnginesProvider = FutureProvider<Set<EngineId>>((ref) async {
  final downloader = ref.read(modelDownloaderProvider);
  final result = <EngineId>{};
  for (final id in EngineId.values) {
    if (id == EngineId.system) {
      result.add(id);
      continue;
    }
    if (await downloader.isEngineDownloaded(id)) {
      result.add(id);
    }
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
          _PhonemizationSettingsCard(),
          const SizedBox(height: 16),
          _SystemEngineCard(isSelected: settings.ttsEngine == EngineId.system),
          const SizedBox(height: 16),
          _KittenEngineCard(
            isSelected: settings.ttsEngine == EngineId.kitten,
          ),
          const SizedBox(height: 16),
          _KokoroEngineCard(isSelected: settings.ttsEngine == EngineId.kokoro),
          const SizedBox(height: 16),
          _SupertonicEngineCard(
            isSelected: settings.ttsEngine == EngineId.supertonic,
          ),
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
        'Uses your device\'s built-in text-to-speech engine.\nNo downloads required.',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = EngineMeta.kitten;
    final installedAsync = ref.watch(installedEnginesProvider);
    final downloadProgress = ref.watch(engineDownloadProgressProvider);
    final isInstalled = installedAsync.when(
      data: (set) => set.contains(EngineId.kitten),
      loading: () => false,
      error: (_, _) => false,
    );
    final progress = downloadProgress[EngineId.kitten];
    final isDownloading = ref
        .read(engineDownloadProgressProvider.notifier)
        .isDownloading(EngineId.kitten);

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
      trailing: _buildAction(ref, isInstalled, isDownloading, EngineId.kitten),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Lightning-fast neural TTS with 8 expressive voices.\n'
              'Requires ~57 MB download.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (isDownloading) ...[
            const SizedBox(height: 12),
            _buildDownloadProgress(context, ref, EngineId.kitten, progress),
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
    EngineId engine,
  ) {
    if (isDownloading) {
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () => ref
            .read(engineDownloadProgressProvider.notifier)
            .cancelDownload(engine),
        child: const Text('Cancel'),
      );
    }
    if (isInstalled) {
      if (isSelected) return const SizedBox.shrink();
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () =>
            ref.read(settingsProvider.notifier).setTtsEngine(engine),
        child: const Text('Select'),
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: () => ref
          .read(engineDownloadProgressProvider.notifier)
          .startDownload(engine),
      child: const Text('Install'),
    );
  }

  Widget _buildDownloadProgress(
    BuildContext context,
    WidgetRef ref,
    EngineId engine,
    Map<String, FileProgress>? progress,
  ) {
    final fraction = ref
        .read(engineDownloadProgressProvider.notifier)
        .getOverallFraction(engine);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = EngineMeta.kokoro;
    final installedAsync = ref.watch(installedEnginesProvider);
    final downloadProgress = ref.watch(engineDownloadProgressProvider);
    final isInstalled = installedAsync.when(
      data: (set) => set.contains(EngineId.kokoro),
      loading: () => false,
      error: (_, _) => false,
    );
    final progress = downloadProgress[EngineId.kokoro];
    final isDownloading = ref
        .read(engineDownloadProgressProvider.notifier)
        .isDownloading(EngineId.kokoro);

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
      trailing: _buildAction(ref, isInstalled, isDownloading, EngineId.kokoro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Kokoro 82M parameter model with 22 expressive voices.\n'
              'Requires ~170 MB download.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (isDownloading) ...[
            const SizedBox(height: 12),
            _buildDownloadProgress(context, ref, EngineId.kokoro, progress),
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
    EngineId engine,
  ) {
    if (isDownloading) {
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () => ref
            .read(engineDownloadProgressProvider.notifier)
            .cancelDownload(engine),
        child: const Text('Cancel'),
      );
    }
    if (isInstalled) {
      if (isSelected) return const SizedBox.shrink();
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () =>
            ref.read(settingsProvider.notifier).setTtsEngine(engine),
        child: const Text('Select'),
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: () => ref
          .read(engineDownloadProgressProvider.notifier)
          .startDownload(engine),
      child: const Text('Install'),
    );
  }

  Widget _buildDownloadProgress(
    BuildContext context,
    WidgetRef ref,
    EngineId engine,
    Map<String, FileProgress>? progress,
  ) {
    final fraction = ref
        .read(engineDownloadProgressProvider.notifier)
        .getOverallFraction(engine);
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

// ── Supertonic Engine ──

class _SupertonicEngineCard extends ConsumerWidget {
  final bool isSelected;

  const _SupertonicEngineCard({required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = EngineMeta.supertonic;
    final installedAsync = ref.watch(installedEnginesProvider);
    final downloadProgress = ref.watch(engineDownloadProgressProvider);
    final isInstalled = installedAsync.when(
      data: (set) => set.contains(EngineId.supertonic),
      loading: () => false,
      error: (_, _) => false,
    );
    final progress = downloadProgress[EngineId.supertonic];
    final isDownloading = ref
        .read(engineDownloadProgressProvider.notifier)
        .isDownloading(EngineId.supertonic);

    return _EngineCard(
      isSelected: isSelected,
      meta: meta,
      engine: EngineId.supertonic,
      installed: isInstalled,
      statusText: isInstalled
          ? 'Installed'
          : isDownloading
          ? 'Downloading...'
          : 'Not installed',
      trailing: _buildAction(
        ref,
        isInstalled,
        isDownloading,
        EngineId.supertonic,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Studio-quality multilingual TTS with 10 voices.\n'
              'Supports EN, KO, ES, PT, FR. Requires ~265 MB download.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (isDownloading) ...[
            const SizedBox(height: 12),
            _buildDownloadProgress(context, ref, EngineId.supertonic, progress),
          ],
          if (isInstalled) ...[
            _VoiceChips(voices: supertonicVoices, engine: EngineId.supertonic),
          ],
        ],
      ),
    );
  }

  Widget _buildAction(
    WidgetRef ref,
    bool isInstalled,
    bool isDownloading,
    EngineId engine,
  ) {
    if (isDownloading) {
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () => ref
            .read(engineDownloadProgressProvider.notifier)
            .cancelDownload(engine),
        child: const Text('Cancel'),
      );
    }
    if (isInstalled) {
      if (isSelected) return const SizedBox.shrink();
      return ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: () =>
            ref.read(settingsProvider.notifier).setTtsEngine(engine),
        child: const Text('Select'),
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: () => ref
          .read(engineDownloadProgressProvider.notifier)
          .startDownload(engine),
      child: const Text('Install'),
    );
  }

  Widget _buildDownloadProgress(
    BuildContext context,
    WidgetRef ref,
    EngineId engine,
    Map<String, FileProgress>? progress,
  ) {
    final fraction = ref
        .read(engineDownloadProgressProvider.notifier)
        .getOverallFraction(engine);
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
              if (trailing != null) trailing!,
            ],
          ),
          if (child != null) child!,
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
  final AudioPlayer _player = AudioPlayer();
  Voice? _playingVoice;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  .map((v) => _voiceChip(v, theme, accent))
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
              children: males.map((v) => _voiceChip(v, theme, accent)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _voiceChip(Voice voice, ThemeData theme, Color accent) {
    final isPlaying = _playingVoice == voice;
    return ActionChip(
      avatar: Icon(
        isPlaying ? Icons.stop : Icons.play_arrow,
        size: 16,
        color: isPlaying
            ? accent
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      label: Text(voice.name),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: isPlaying ? accent : theme.colorScheme.onSurface,
        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isPlaying
          ? accent.withValues(alpha: 0.1)
          : Colors.transparent,
      side: BorderSide(
        color: isPlaying
            ? accent.withValues(alpha: 0.3)
            : theme.colorScheme.outline.withValues(alpha: 0.2),
      ),
      onPressed: () => _togglePreview(voice),
    );
  }

  Future<void> _togglePreview(Voice voice) async {
    if (_playingVoice == voice) {
      await _player.stop();
      setState(() => _playingVoice = null);
      return;
    }
    try {
      await ref.read(tts.ttsProvider.notifier).previewVoice(voice);
      setState(() => _playingVoice = voice);
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

class _PhonemizationSettingsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ShadCard(
      title: const Text('Phonemization Settings'),
      description: const Text('Improve pronunciation using IPA phonemes.'),
      child: Column(
        children: [
          ShadSwitch(
            value: settings.usePhonemizer && settings.useEspeak,
            onChanged: (v) {
              if (v) {
                ref.read(settingsProvider.notifier).setUsePhonemizer(true);
                ref.read(settingsProvider.notifier).setUseEspeak(true);
              } else {
                ref.read(settingsProvider.notifier).setUsePhonemizer(false);
              }
            },
            label: const Text('Use Espeak-NG (Recommended)'),
            sublabel: const Text('High-fidelity IPA phonemization'),
          ),
          const SizedBox(height: 12),
          ShadSwitch(
            value: settings.usePhonemizer && !settings.useEspeak,
            onChanged: (v) {
              if (v) {
                ref.read(settingsProvider.notifier).setUsePhonemizer(true);
                ref.read(settingsProvider.notifier).setUseEspeak(false);
              } else {
                ref.read(settingsProvider.notifier).setUsePhonemizer(false);
              }
            },
            label: const Text('Use Rule-based (Legacy)'),
            sublabel: const Text('Lightweight but less accurate'),
          ),
        ],
      ),
    );
  }
}
