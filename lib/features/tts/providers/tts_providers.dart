import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import 'tts_model_providers.dart';
import '../data/piper_tts_model.dart';
import 'tts_worker.dart';

final ttsProvider = NotifierProvider<TtsNotifier, TtsState>(() {
  return TtsNotifier();
});

class TtsState {
  final bool isSpeaking;
  final bool isPaused;
  final bool isInitializing;
  final String? error;
  final EngineId? activeEngine;
  final String? playingContent;
  final bool isPreview;

  const TtsState({
    this.isSpeaking = false,
    this.isPaused = false,
    this.isInitializing = false,
    this.error,
    this.activeEngine,
    this.playingContent,
    this.isPreview = false,
  });

  TtsState copyWith({
    bool? isSpeaking,
    bool? isPaused,
    bool? isInitializing,
    String? error,
    EngineId? activeEngine,
    String? playingContent,
    bool? isPreview,
  }) {
    return TtsState(
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isPaused: isPaused ?? this.isPaused,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      activeEngine: activeEngine ?? this.activeEngine,
      playingContent: playingContent,
      isPreview: isPreview ?? this.isPreview,
    );
  }
}

class TtsNotifier extends Notifier<TtsState> {
  FlutterTts? _flutterTts;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlayerDisposed = false;
  bool _isStopping = false;
  List<String> _chunks = [];
  int _currentChunkIndex = 0;
  EngineId? _currentEngine;
  String? _currentVoice;
  String? _currentModelPath;
  String? _currentVoicesPath;
  String? _currentTokensPath;
  String? _currentDataDir;
  String? _currentLexicon;

  // Isolate worker fields
  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  final ReceivePort _mainReceivePort = ReceivePort();
  final Map<int, Uint8List> _synthesizedChunks = {};
  int _lastEnqueuedChunk = -1;
  static const int _lookAheadCount = 2;
  Completer<void>? _initCompleter;
  bool _isWorkerInitializing = false;
  int _currentSessionId = 0;

  StreamSubscription<void>? _playerCompleteSubscription;
  int _playbackSessionId = 0;
  Completer<SendPort>? _workerPortCompleter;

  bool _isPreview = false;
  final Map<int, AudioSource> _playlistBuffer = {};
  int _nextPlaylistIndexToAdd = 0;
  StreamSubscription<int?>? _currentIndexSubscription;

  // Progress tracking
  final Map<int, Duration> _chunkDurations = {};
  Duration _totalDuration = Duration.zero;
  Duration _chunkOffset = Duration.zero;
  final StreamController<void> _onChunkChanged = StreamController<void>.broadcast();

  AudioPlayer get player => _player;
  Stream<Duration> get onPositionChanged => _player.positionStream;
  Duration get totalDuration => _totalDuration;
  Duration get chunkOffset => _chunkOffset;
  Stream<void> get onChunkChanged => _onChunkChanged.stream;

  @override
  TtsState build() {
    ref.keepAlive();

    ref.listen(settingsProvider, (previous, next) {
      if (previous?.ttsEngine != next.ttsEngine) {
        state = state.copyWith(activeEngine: next.ttsEngine);
      }
    });

    _player.setAudioSources([]);

    _playerCompleteSubscription = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _onPlaybackFinished();
      }
    });

    _currentIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentChunkIndex) {
        _currentChunkIndex = index;
        _onChunkChanged.add(null);
        _enqueueNextChunks();
      }
    });

    _setupWorkerListener();

    ref.onDispose(() {
      _workerPortCompleter?.completeError(StateError('Disposed'));
      _workerPortCompleter = null;
      _workerIsolate?.kill();
      _mainReceivePort.close();
      _playerCompleteSubscription?.cancel();
      _currentIndexSubscription?.cancel();
      _onChunkChanged.close();
      if (!_isPlayerDisposed) {
        _isPlayerDisposed = true;
        try {
          _player.dispose();
        } catch (_) {}
      }
    });

    final settings = ref.read(settingsProvider);
    return TtsState(activeEngine: settings.ttsEngine);
  }

  void _setupWorkerListener() {
    _mainReceivePort.listen((message) async {
      if (message is SendPort) {
        _workerSendPort = message;
        _workerPortCompleter?.complete(message);
        _workerPortCompleter = null;
      } else if (message is TtsWorkerResponse) {
        if (message.isInitResponse) {
          _initCompleter?.complete();
          _initCompleter = null;
        } else if (message.chunkIndex != null) {
          if (message.sessionId != _currentSessionId) {
            Log.debug('Ignoring stale chunk ${message.chunkIndex}');
            return;
          }
          if (message.wavBytes != null) {
            _synthesizedChunks[message.chunkIndex!] = message.wavBytes!;
            _computeChunkDuration(message.chunkIndex!, message.wavBytes!);
            await _addChunkToPlaylist(message.chunkIndex!, message.wavBytes!);
          } else {
            Log.error(
              'Worker error for chunk ${message.chunkIndex}: ${message.error}',
            );
            _synthesizedChunks[message.chunkIndex!] = Uint8List(0);
            await _addChunkToPlaylist(message.chunkIndex!, Uint8List(0));
          }
        } else if (message.error != null) {
          Log.error('Worker general error: ${message.error}');
          _initCompleter?.completeError(message.error!);
          _initCompleter = null;
        }
      }
    });
  }

  Future<void> _ensureWorker() async {
    if (_workerIsolate != null) return;

    Log.info('Spawning TTS worker isolate...');
    _workerPortCompleter = Completer<SendPort>();
    _workerIsolate = await Isolate.spawn(
      ttsWorkerEntry,
      _mainReceivePort.sendPort,
    );

    await _workerPortCompleter!.future.timeout(
      const Duration(seconds: 10),
    );
  }

  void _computeChunkDuration(int index, Uint8List wavBytes) {
    if (wavBytes.length < 44) return;
    final data = ByteData.view(wavBytes.buffer, wavBytes.offsetInBytes, 44);
    final sampleRate = data.getUint32(24, Endian.little);
    final dataSize = data.getUint32(40, Endian.little);
    final sampleCount = dataSize ~/ 2;
    final durationMs = (sampleCount * 1000) ~/ sampleRate;
    _chunkDurations[index] = Duration(milliseconds: durationMs);
    _totalDuration = Duration.zero;
    for (final d in _chunkDurations.values) {
      _totalDuration += d;
    }
  }

  void _resetProgress() {
    _chunkDurations.clear();
    _totalDuration = Duration.zero;
    _chunkOffset = Duration.zero;
  }

  void _deleteChunkFile(int sessionId, int chunkIndex) {
    if (chunkIndex < 0) return;
    try {
      final tempFile = File(
        '${Directory.systemTemp.path}/tts_chunk_${sessionId}_$chunkIndex.wav',
      );
      if (tempFile.existsSync()) tempFile.deleteSync();
    } catch (_) {}
  }

  void _cleanupSessionFiles(int sessionId, int chunkCount) {
    for (var i = 0; i < chunkCount; i++) {
      _deleteChunkFile(sessionId, i);
    }
  }

  void _onPlaybackFinished() {
    if (_isStopping) return;
    if (_currentSessionId != _playbackSessionId) return;
    _cleanupSessionFiles(_currentSessionId, _chunks.length);
    _resetProgress();
    state = state.copyWith(
      isSpeaking: false,
      isPaused: false,
      isInitializing: false,
      playingContent: null,
      isPreview: false,
    );
  }

  List<String> _splitText(String text) {
    if (text.length <= 250) return [text];

    final regex = RegExp(r'(?<=[.!?])\s+');
    final sentences = text.split(regex);

    final List<String> chunks = [];
    String currentChunk = "";

    for (final sentence in sentences) {
      if ((currentChunk.length + sentence.length) > 250 &&
          currentChunk.isNotEmpty) {
        chunks.add(currentChunk.trim());
        currentChunk = "";
      }

      if (sentence.length > 250) {
        final subRegex = RegExp(r'(?<=[,;])\s+');
        final parts = sentence.split(subRegex);
        for (final part in parts) {
          if ((currentChunk.length + part.length) > 250 &&
              currentChunk.isNotEmpty) {
            chunks.add(currentChunk.trim());
            currentChunk = "";
          }
          currentChunk += "$part ";
        }
      } else {
        currentChunk += "$sentence ";
      }
    }

    if (currentChunk.trim().isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  Future<void> _initEngine(EngineId engineId, {String? voiceId}) async {
    await _ensureWorker();

    if (_isWorkerInitializing && _initCompleter != null) {
      await _initCompleter!.future.timeout(
        const Duration(seconds: 30),
      );
    }

    String modelPath = '';
    String voicesPath = '';
    String tokensPath = '';
    String dataDir = '';
    String lexicon = '';

    switch (engineId) {
      case EngineId.kitten:
        final variant = ref.read(settingsProvider).kittenTtsModelVariant;
        final kittenDl = ref.read(kittenTtsDownloaderProvider);
        final mPath = await kittenDl.getModelPath(variant);
        final vPath = await kittenDl.getVoicesPath(variant);
        final tPath = await kittenDl.getTokensPath(variant);
        final dDir = await kittenDl.getDataDir(variant);
        if (mPath == null || vPath == null || tPath == null) {
          throw StateError(
            'Kitten model files not found for ${variant.name}. Please download them in the Model Manager.',
          );
        }
        modelPath = mPath;
        voicesPath = vPath;
        tokensPath = tPath;
        dataDir = dDir.path;
        break;
      case EngineId.piper:
        final selectedVoiceId =
            voiceId ??
            ref.read(settingsProvider).ttsVoiceId ??
            piperVoices.first.id;
        final requestedVariant = PiperTtsModelVariant.values.firstWhere(
          (v) => v.id == selectedVoiceId,
          orElse: () => PiperTtsModelVariant.enUsLessacMedium,
        );
        final downloader = ref.read(piperTtsDownloaderProvider);
        final downloadedVariants = await downloader.getDownloadedVariants();
        final variant = downloadedVariants.contains(requestedVariant)
            ? requestedVariant
            : downloadedVariants.isNotEmpty
            ? downloadedVariants.first
            : requestedVariant;
        final mPath = await downloader.getModelPath(variant);
        final tPath = await downloader.getTokensPath(variant);
        final dDir = await downloader.getDataDir(variant);
        if (mPath == null || tPath == null) {
          throw StateError(
            'Piper voice files not found for ${variant.displayName}. Please download them in the Model Manager.',
          );
        }
        modelPath = mPath;
        tokensPath = tPath;
        dataDir = dDir.path;
        break;
      default:
        return;
    }

    if (_currentEngine == engineId &&
        !_isWorkerInitializing &&
        _currentModelPath == modelPath &&
        _currentVoicesPath == voicesPath &&
        _currentTokensPath == tokensPath &&
        _currentDataDir == dataDir &&
        _currentLexicon == lexicon) {
      return;
    }

    _isWorkerInitializing = true;

    try {
      _initCompleter = Completer<void>();
      _workerSendPort!.send(
        TtsInitRequest(
          engineId: engineId,
          modelPath: modelPath,
          voicesPath: voicesPath,
          tokensPath: tokensPath,
          dataDir: dataDir,
          lexicon: lexicon,
        ),
      );

      await _initCompleter!.future.timeout(
        const Duration(seconds: 30),
      );
      _currentEngine = engineId;
      _currentModelPath = modelPath;
      _currentVoicesPath = voicesPath;
      _currentTokensPath = tokensPath;
      _currentDataDir = dataDir;
      _currentLexicon = lexicon;
    } finally {
      _isWorkerInitializing = false;
    }
  }

  Future<void> speak(String text, {EngineId? engineId, String? voiceId, bool isPreview = false}) async {
    if (text.trim().isEmpty) return;

    _isStopping = false;
    if (state.isSpeaking) {
      await stop();
      await Future.delayed(const Duration(milliseconds: 100));
      _isStopping = false;
    }

    final settings = ref.read(settingsProvider);
    engineId ??= settings.ttsEngine;

    final availableVoices = voicesForEngine(engineId);
    final resolvedVoiceId =
        voiceId ??
        settings.ttsVoiceId ??
        (availableVoices.isNotEmpty ? availableVoices.first.id : null);

    if (engineId == EngineId.system) {
      _flutterTts ??= FlutterTts();
      // Clear any previous handlers to prevent stale callbacks
      _flutterTts!.setCompletionHandler(() {});
      _flutterTts!.setErrorHandler((_) {});
      _flutterTts!.setCancelHandler(() {});
      state = state.copyWith(
        isSpeaking: true,
        isInitializing: false,
        error: null,
        activeEngine: EngineId.system,
        playingContent: text,
        isPreview: isPreview,
      );
      try {
        await _flutterTts!.setLanguage('en-US');
        await _flutterTts!.setSpeechRate(
          (settings.ttsSpeed * 0.5).clamp(0.0, 1.0),
        );
        _flutterTts!.setCompletionHandler(() {
          if (!_isStopping) {
            state = state.copyWith(isSpeaking: false, playingContent: null);
          }
        });
        _flutterTts!.setErrorHandler((msg) {
          if (!_isStopping) {
            state = state.copyWith(
              isSpeaking: false,
              playingContent: null,
              error: msg.toString(),
            );
          }
        });
        _flutterTts!.setCancelHandler(() {
          if (!_isStopping) {
            state = state.copyWith(isSpeaking: false, playingContent: null);
          }
        });
        await _flutterTts!.awaitSpeakCompletion(true);
        await _flutterTts!.speak(text);
      } catch (e) {
        state = state.copyWith(
          isSpeaking: false,
          error: 'System TTS unavailable',
          playingContent: null,
        );
        rethrow;
      }
      return;
    }

    _resetProgress();
    _chunks = _splitText(text);
    _currentChunkIndex = 0;
    _currentVoice = resolvedVoiceId;
    _synthesizedChunks.clear();
    _lastEnqueuedChunk = -1;
    _currentSessionId++;
    _playbackSessionId = _currentSessionId;

    _isPreview = isPreview;
    _playlistBuffer.clear();
    _nextPlaylistIndexToAdd = 0;
    await _player.clearAudioSources();

    try {
      AudioSession.instance.then((session) {
        session.configure(const AudioSessionConfiguration.speech());
      });
    } catch (e) {
      Log.error('Error configuring audio session: $e');
    }

    state = state.copyWith(
      isSpeaking: true,
      isPaused: false,
      isInitializing: true,
      error: null,
      activeEngine: engineId,
      playingContent: text,
      isPreview: isPreview,
    );

    try {
      await _initEngine(engineId, voiceId: resolvedVoiceId);
      state = state.copyWith(isInitializing: false);
      _enqueueNextChunks();
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

  Future<void> _addChunkToPlaylist(int chunkIndex, Uint8List wavBytes) async {
    if (_isStopping || chunkIndex >= _chunks.length) return;

    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/tts_chunk_${_currentSessionId}_$chunkIndex.wav',
    );
    await tempFile.writeAsBytes(wavBytes);

    final source = AudioSource.file(
      tempFile.path,
      tag: _isPreview ? null : MediaItem(
        id: 'tts_chunk_${_currentSessionId}_$chunkIndex',
        album: 'LocalMind TTS',
        title: _chunks[chunkIndex],
        artist: _currentEngine == EngineId.kitten ? 'Kitten TTS' : 'Piper TTS',
      ),
    );

    _playlistBuffer[chunkIndex] = source;
    while (_playlistBuffer.containsKey(_nextPlaylistIndexToAdd)) {
      final src = _playlistBuffer.remove(_nextPlaylistIndexToAdd)!;
      await _player.addAudioSource(src);

      if (_nextPlaylistIndexToAdd == 0) {
        if (!state.isPaused) {
          _player.play();
        }
      }

      _nextPlaylistIndexToAdd++;
    }
  }

  void _enqueueNextChunks() {
    if (_workerSendPort == null || _currentEngine == null) return;

    final settings = ref.read(settingsProvider);
    final availableVoices = voicesForEngine(_currentEngine!);
    final voiceId =
        _currentVoice ??
        settings.ttsVoiceId ??
        (availableVoices.isNotEmpty ? availableVoices.first.id : null);

    while (_lastEnqueuedChunk < _chunks.length - 1 &&
        _lastEnqueuedChunk < _currentChunkIndex + _lookAheadCount) {
      _lastEnqueuedChunk++;
      final chunkIndex = _lastEnqueuedChunk;
      final text = _chunks[chunkIndex];

      Log.debug('Enqueuing synthesis for chunk $chunkIndex');
      _workerSendPort!.send(
        TtsSynthesizeRequest(
          text: text,
          voiceId: voiceId ?? '',
          speed: settings.ttsSpeed,
          chunkIndex: chunkIndex,
          sessionId: _currentSessionId,
        ),
      );
    }
  }

  void pause() {
    if (state.isPaused || !state.isSpeaking) return;
    _player.pause();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.isPaused) return;
    _player.play();
    state = state.copyWith(isPaused: false);
  }

  void togglePauseResume() {
    if (state.isPaused) {
      resume();
    } else if (state.isSpeaking) {
      pause();
    }
  }

  Future<void> stop() async {
    _isStopping = true;
    if (_isPlayerDisposed) return;
    try {
      await _player.stop();
      await _player.clearAudioSources();
    } catch (_) {}
    await _flutterTts?.stop();
    _cleanupSessionFiles(_currentSessionId, _chunks.length);
    _resetProgress();
    state = state.copyWith(
      isSpeaking: false,
      isPaused: false,
      isInitializing: false,
      playingContent: null,
      isPreview: false,
    );
  }

  Future<void> previewVoice(Voice voice) async {
    await speak(ttsPreviewSample, engineId: voice.engine, voiceId: voice.id, isPreview: true);
  }
}

const ttsPreviewSample = "Hello, this is a preview of the selected voice";
