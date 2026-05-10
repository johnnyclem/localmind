import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:meomeo/meomeo.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import 'tts_model_providers.dart';

final ttsProvider = NotifierProvider<TtsNotifier, TtsState>(() {
  return TtsNotifier();
});

class TtsState {
  final bool isSpeaking;
  final bool isInitializing;
  final String? error;
  final EngineId? activeEngine;
  final String? playingContent;

  const TtsState({
    this.isSpeaking = false,
    this.isInitializing = false,
    this.error,
    this.activeEngine,
    this.playingContent,
  });

  TtsState copyWith({
    bool? isSpeaking,
    bool? isInitializing,
    String? error,
    EngineId? activeEngine,
    String? playingContent,
  }) {
    return TtsState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      activeEngine: activeEngine ?? this.activeEngine,
      playingContent: playingContent,
    );
  }
}

class TtsNotifier extends Notifier<TtsState> {
  MeoKitten? _kitten;
  MeoKokoro? _kokoro;
  MeoPiper? _piper;
  FlutterTts? _flutterTts;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlayerDisposed = false;

  @override
  TtsState build() {
    ref.keepAlive();
    final settings = ref.watch(settingsProvider);
    _player.onPlayerComplete.listen((_) {
      _onPlaybackFinished();
    });
    ref.onDispose(() {
      _kitten?.dispose();
      _kokoro?.dispose();
      _piper?.dispose();
      if (!_isPlayerDisposed) {
        _isPlayerDisposed = true;
        try {
          _player.dispose();
        } catch (_) {}
      }
    });

    return TtsState(activeEngine: settings.ttsEngine);
  }

  void _onPlaybackFinished() {
    if (_isPlayerDisposed || !state.isSpeaking) return;
    state = state.copyWith(
      isSpeaking: false,
      isInitializing: false,
      playingContent: null,
    );
  }

  Future<void> _ensureEspeakData(String targetPath) async {
    final dir = Directory(targetPath);
    if (await dir.exists()) {
      // Basic check: if it has espeak-ng-data, assume it's valid
      if (await Directory('$targetPath/espeak-ng-data').exists()) {
        return;
      }
    }

    Log.info('Extracting espeak-data.zip to $targetPath...');
    try {
      final data = await rootBundle.load('assets/espeak-data.zip');
      final bytes = data.buffer.asUint8List();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final f = File('$targetPath/$filename');
          await f.create(recursive: true);
          await f.writeAsBytes(data);
        } else {
          await Directory('$targetPath/$filename').create(recursive: true);
        }
      }
      Log.info('espeak-data extraction complete.');
    } catch (e) {
      Log.error('Failed to extract espeak-data: $e');
      rethrow;
    }
  }

  Future<void> _initEngine(EngineId engineId) async {
    final supportDir = await getApplicationSupportDirectory();
    final resolvedEspeakPath = '${supportDir.path}/espeak-data';

    // Ensure espeak-data is available for neural engines
    if (engineId != EngineId.system) {
      await _ensureEspeakData(resolvedEspeakPath);
    }

    switch (engineId) {
      case EngineId.kitten:
        if (_kitten != null) return;
        final kittenDl = ref.read(kittenTtsDownloaderProvider);
        final variant = ref.read(settingsProvider).kittenTtsModelVariant;
        final modelPath = await kittenDl.getFilePath(
          variant,
          variant.modelFileName,
        );
        final voicesPath = await kittenDl.getFilePath(variant, 'voices.npz');
        if (modelPath == null || voicesPath == null) {
          throw StateError(
            'Kitten model files not found. Please download them in the Model Manager.',
          );
        }
        _kitten = MeoKitten(
          model: modelPath,
          voices: voicesPath,
          espeakData: resolvedEspeakPath,
        );
        break;
      case EngineId.kokoro:
        if (_kokoro != null) return;
        final kokoroDl = ref.read(kokoroTtsDownloaderProvider);
        final variant =
            ref.read(settingsProvider).kokoroTtsModelVariant;
        final modelPath = await kokoroDl.getModelPath(variant);
        final voicesDir = await kokoroDl.getVoicesDir(variant);
        if (modelPath == null) {
          throw StateError(
            'Kokoro model file not found. Please download it in the Model Manager.',
          );
        }
        _kokoro = MeoKokoro(
          model: modelPath,
          voices: voicesDir.path,
          espeakData: resolvedEspeakPath,
        );
        break;
      case EngineId.piper:
        if (_piper != null) return;
        final downloader = ref.read(modelDownloaderProvider);
        final ttsDir = await downloader.getTtsDir();
        final modelPath = '${ttsDir.path}/piper/model.onnx';
        if (!await File(modelPath).exists()) {
          throw StateError('Piper model file not found.');
        }
        _piper = MeoPiper(model: modelPath, espeakData: resolvedEspeakPath);
        break;
      default:
        break;
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    if (state.isSpeaking) {
      await stop();
    }

    final settings = ref.read(settingsProvider);
    final engineId = settings.ttsEngine;

    if (engineId == EngineId.system) {
      _flutterTts ??= FlutterTts();
      state = state.copyWith(
        isSpeaking: true,
        isInitializing: false,
        error: null,
        activeEngine: EngineId.system,
        playingContent: text,
      );
      try {
        await _flutterTts!.setLanguage('en-US');
        await _flutterTts!.setSpeechRate(
          (settings.ttsSpeed * 0.5).clamp(0.0, 1.0),
        );
        await _flutterTts!.awaitSpeakCompletion(true);
        await _flutterTts!.speak(text);
      } catch (e) {
        state = state.copyWith(
          isSpeaking: false,
          error: 'System TTS unavailable',
          playingContent: null,
        );
        rethrow;
      } finally {
        state = state.copyWith(
          isSpeaking: false,
          playingContent: null,
        );
      }
      return;
    }

    state = state.copyWith(
      isSpeaking: true,
      isInitializing: true,
      error: null,
      activeEngine: engineId,
      playingContent: text,
    );

    try {
      await _initEngine(engineId);
      state = state.copyWith(isInitializing: false);

      final voiceId = settings.ttsVoiceId ?? 'Luna';
      final speaker = Speaker(voice: voiceId, speed: settings.ttsSpeed);

      Float32List? pcm;
      int sampleRate = 22050;

      if (engineId == EngineId.kitten) {
        pcm = await _kitten?.speak(text, speaker: speaker);
        sampleRate = 24000; // Kitten default
      } else if (engineId == EngineId.kokoro) {
        pcm = await _kokoro?.speak(text, speaker: speaker);
        sampleRate = 24000; // Kokoro default
      } else if (engineId == EngineId.piper) {
        pcm = await _piper?.speak(text, speaker: speaker);
        sampleRate = 22050; // Piper default often 22050
      }

      if (pcm != null) {
        final wavBytes = _createWav(pcm, sampleRate);
        try {
          await _player.play(BytesSource(wavBytes));
        } catch (e) {
          Log.error('AudioPlayer play error: $e');
        }
      }
    } catch (e, st) {
      if (_isPlayerDisposed) return;
      Log.error('TTS speak error: $e\n$st');
      state = state.copyWith(
        isSpeaking: false,
        isInitializing: false,
        error: e.toString(),
        playingContent: null,
      );
    }
  }

  Future<void> stop() async {
    if (_isPlayerDisposed) return;
    try {
      await _player.stop();
    } catch (_) {}
    await _flutterTts?.stop();
    state = state.copyWith(
      isSpeaking: false,
      isInitializing: false,
      playingContent: null,
    );
  }

  Uint8List _createWav(Float32List samples, int sampleRate) {
    // Simple WAV header creation
    final int byteCount = samples.length * 2;
    final int totalSize = 36 + byteCount;
    final Uint8List wav = Uint8List(44 + byteCount);
    final ByteData data = ByteData.view(wav.buffer);

    data.setUint8(0, 0x52); // R
    data.setUint8(1, 0x49); // I
    data.setUint8(2, 0x46); // F
    data.setUint8(3, 0x46); // F
    data.setUint32(4, totalSize, Endian.little);
    data.setUint8(8, 0x57); // W
    data.setUint8(9, 0x41); // A
    data.setUint8(10, 0x56); // V
    data.setUint8(11, 0x45); // E
    data.setUint8(12, 0x66); // f
    data.setUint8(13, 0x6d); // m
    data.setUint8(14, 0x74); // t
    data.setUint8(15, 0x20); // space
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // Mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little); // 16-bit
    data.setUint8(36, 0x64); // d
    data.setUint8(37, 0x61); // a
    data.setUint8(38, 0x74); // t
    data.setUint8(39, 0x61); // a
    data.setUint32(40, byteCount, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      final int sample = (samples[i] * 32767).clamp(-32768, 32767).toInt();
      data.setInt16(44 + (i * 2), sample, Endian.little);
    }

    return wav;
  }

  Future<void> previewVoice(Voice voice) async {
    final settings = ref.read(settingsProvider);
    final previousEngine = settings.ttsEngine;
    final previousVoiceId = settings.ttsVoiceId;
    ref.read(settingsProvider.notifier).setTtsEngine(voice.engine);
    ref.read(settingsProvider.notifier).setTtsVoiceId(voice.id);
    await speak(ttsPreviewSample);
    ref.read(settingsProvider.notifier).setTtsEngine(previousEngine);
    if (previousVoiceId != null) {
      ref.read(settingsProvider.notifier).setTtsVoiceId(previousVoiceId);
    }
  }
}

const ttsPreviewSample = "Hello, this is a preview of the selected voice.";
