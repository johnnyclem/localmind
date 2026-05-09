import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/features/tts/providers/tts_model_providers.dart'
    hide Log;
import 'package:neural_tts/neural_tts.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';

final ttsRuntimeProvider = Provider<TTSRuntime>((ref) {
  return TTSRuntime.instance;
});

final ttsProvider = NotifierProvider<TtsNotifier, TtsState>(() {
  return TtsNotifier();
});

class TtsState {
  final bool isSpeaking;
  final bool isInitializing;
  final String? error;
  final EngineId? activeEngine;

  const TtsState({
    this.isSpeaking = false,
    this.isInitializing = false,
    this.error,
    this.activeEngine,
  });

  TtsState copyWith({
    bool? isSpeaking,
    bool? isInitializing,
    String? error,
    EngineId? activeEngine,
  }) {
    return TtsState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      activeEngine: activeEngine ?? this.activeEngine,
    );
  }
}

class TtsNotifier extends Notifier<TtsState> {
  Engine? _currentEngine;
  final Phonemizer _phonemizer = Phonemizer();
  EspeakPhonemizer? _espeakPhonemizer;

  @override
  TtsState build() {
    final settings = ref.watch(settingsProvider);
    ref.onDispose(() {
      _currentEngine?.release();
    });

    // Initialize espeak data if pre-bundled
    _initEspeak();

    return TtsState(activeEngine: settings.ttsEngine);
  }

  Future<void> _initEspeak() async {
    final downloader = ref.read(modelDownloaderProvider);
    final ttsDir = await downloader.getTtsDir();
    final espeakDir = Directory('${ttsDir.path}/espeak-ng-data');

    if (await espeakDir.exists()) {
      try {
        _espeakPhonemizer = EspeakPhonemizer(
          dataPath: ttsDir.path,
          language: 'en-us',
        );
      } catch (e) {
        Log.error('Failed to init EspeakPhonemizer: $e');
      }
    }
  }

  Voice? get _currentVoice {
    final settings = ref.read(settingsProvider);
    return voiceFromSettings(settings.ttsVoiceId, settings.ttsEngine);
  }

  Future<Engine> _resolveEngine() async {
    if (_currentEngine != null) return _currentEngine!;
    final engine = createEngine(ref.read(settingsProvider).ttsEngine);
    _currentEngine = engine;
    return engine;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    final settings = ref.read(settingsProvider);
    final engineId = settings.ttsEngine;

    state = state.copyWith(
      isSpeaking: true,
      isInitializing: engineId != EngineId.system,
      error: null,
      activeEngine: engineId,
    );

    try {
      final voice = _currentVoice;
      final engine = await _resolveEngine();
      final runtime = TTSRuntime.instance;
      runtime.resetStop();
      await runtime.acquire(engine, () async {
        final resultVoice = voice ?? (await engine.getVoices()).firstOrNull;
        if (resultVoice == null) {
          throw StateError('No voice available for engine ${engine.id}');
        }

        // Set phonemizer based on settings
        if (settings.useEspeak && _espeakPhonemizer != null) {
          engine.setPhonemizer(_espeakPhonemizer!);
        } else {
          engine.setPhonemizer(_phonemizer);
        }

        await engine.play(
          text,
          resultVoice,
          language: 'en',
          inferenceSteps: settings.supertonicSteps,
          phonemize: settings.usePhonemizer,
        );
      });
    } catch (e, st) {
      Log.error('TTS speak error: $e\n$st');
      state = state.copyWith(
        isSpeaking: false,
        isInitializing: false,
        error: e.toString(),
      );
      rethrow;
    } finally {
      state = state.copyWith(isSpeaking: false, isInitializing: false);
    }
  }

  Future<void> stop() async {
    await TTSRuntime.instance.stop();
    _currentEngine?.stop();
    state = state.copyWith(isSpeaking: false, isInitializing: false);
  }

  Future<void> release() async {
    await TTSRuntime.instance.release();
    if (_currentEngine != null) {
      await _currentEngine!.release();
      _currentEngine = null;
    }
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> previewVoice(Voice voice) async {
    state = state.copyWith(isSpeaking: true, isInitializing: true, error: null);
    final settings = ref.read(settingsProvider);
    try {
      final engine = createEngine(voice.engine);
      final runtime = TTSRuntime.instance;
      runtime.resetStop();
      await runtime.acquire(engine, () async {
        // Set phonemizer based on settings
        if (settings.useEspeak && _espeakPhonemizer != null) {
          engine.setPhonemizer(_espeakPhonemizer!);
        } else {
          engine.setPhonemizer(_phonemizer);
        }

        await engine.play(
          ttsPreviewSample,
          voice,
          language: 'en',
          phonemize: settings.usePhonemizer,
        );
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isSpeaking: false, isInitializing: false);
    }
  }
}
