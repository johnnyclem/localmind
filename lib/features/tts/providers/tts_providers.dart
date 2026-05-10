import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import 'tts_model_providers.dart';
import 'tts_worker.dart';

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
  FlutterTts? _flutterTts;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlayerDisposed = false;
  bool _isStopping = false;
  List<String> _chunks = [];
  int _currentChunkIndex = 0;
  EngineId? _currentEngine;
  String? _currentVoice;

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

  @override
  TtsState build() {
    ref.keepAlive();

    // Listen for engine changes to update the state without rebuilding the whole notifier
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.ttsEngine != next.ttsEngine) {
        state = state.copyWith(activeEngine: next.ttsEngine);
      }
    });

    _player.onPlayerComplete.listen((_) {
      _onChunkFinished();
    });

    _setupWorkerListener();

    ref.onDispose(() {
      _workerIsolate?.kill();
      _mainReceivePort.close();
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
    _mainReceivePort.listen((message) {
      if (message is SendPort) {
        _workerSendPort = message;
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
            // If this was the chunk we were waiting for, play it
            if (message.chunkIndex == _currentChunkIndex && state.isSpeaking) {
              _playNextChunk();
            }
          } else {
            Log.error(
              'Worker error for chunk ${message.chunkIndex}: ${message.error}',
            );
            if (message.chunkIndex == _currentChunkIndex) {
              _onChunkFinished();
            }
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
    _workerIsolate = await Isolate.spawn(
      ttsWorkerEntry,
      _mainReceivePort.sendPort,
    );

    // Wait for worker to send its SendPort
    int attempts = 0;
    while (_workerSendPort == null && attempts < 200) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    if (_workerSendPort == null) {
      throw StateError('Failed to establish communication with TTS worker');
    }
  }

  void _onPlaybackFinished() {
    if (_isStopping) return;
    state = state.copyWith(
      isSpeaking: false,
      isInitializing: false,
      playingContent: null,
    );
  }

  void _onChunkFinished() {
    if (_isStopping) return;
    _currentChunkIndex++;
    if (_currentChunkIndex < _chunks.length) {
      _playNextChunk();
    } else {
      _onPlaybackFinished();
    }
  }

  List<String> _splitText(String text) {
    if (text.length <= 250) return [text];

    // Split by common sentence terminators but keep them
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
        // If a single sentence is too long, split it by commas or spaces
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

  Future<void> _ensureEspeakData(String targetPath) async {
    final dir = Directory(targetPath);
    final espeakNgDataDir = Directory('$targetPath/espeak-ng-data');
    final voicesDir = Directory('$targetPath/espeak-ng-data/voices');
    Log.info('Checking espeak-data at $targetPath');
    if (await espeakNgDataDir.exists() && await voicesDir.exists()) {
      final entities = await espeakNgDataDir.list().toList();
      if (entities.length > 5) {
        Log.info('espeak-data looks valid with ${entities.length} entities.');
        return;
      }
    }

    Log.info(
      'espeak-data invalid or missing. (Re)extracting espeak-data.zip to $targetPath...',
    );
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (e) {
        Log.error('Failed to clear old espeak-data: $e');
      }
    }
    await dir.create(recursive: true);
    try {
      final data = await rootBundle.load('assets/espeak-data.zip');
      final bytes = data.buffer.asUint8List();

      await Isolate.run(() async {
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          String filename = file.name;
          if (filename.startsWith('espeak-data/')) {
            filename = filename.substring('espeak-data/'.length);
          }
          if (filename.isEmpty) continue;

          if (file.isFile) {
            final fileData = file.content as List<int>;
            final f = File('$targetPath/$filename');
            await f.create(recursive: true);
            await f.writeAsBytes(fileData);
          } else {
            await Directory('$targetPath/$filename').create(recursive: true);
          }
        }
      });
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

    await _ensureWorker();

    if (_currentEngine == engineId && !_isWorkerInitializing) return;
    _isWorkerInitializing = true;

    String modelPath = '';
    String voicesPath = '';

    switch (engineId) {
      case EngineId.kitten:
        final variant = ref.read(settingsProvider).kittenTtsModelVariant;
        final kittenDl = ref.read(kittenTtsDownloaderProvider);
        final mPath = await kittenDl.getFilePath(
          variant,
          variant.modelFileName,
        );
        final vPath = await kittenDl.getFilePath(variant, 'voices.npz');
        if (mPath == null || vPath == null) {
          throw StateError(
            'Kitten model files not found for ${variant.name}. Please download them in the Model Manager.',
          );
        }
        modelPath = mPath;
        voicesPath = vPath;
        break;
      case EngineId.kokoro:
        final variant = ref.read(settingsProvider).kokoroTtsModelVariant;
        final kokoroDl = ref.read(kokoroTtsDownloaderProvider);
        final mPath = await kokoroDl.getModelPath(variant);
        final vDir = await kokoroDl.getVoicesDir(variant);
        if (mPath == null) {
          throw StateError(
            'Kokoro model files not found for ${variant.name}. Please download them in the Model Manager.',
          );
        }
        modelPath = mPath;
        voicesPath = vDir.path;
        break;
      case EngineId.piper:
        final downloader = ref.read(modelDownloaderProvider);
        final ttsDir = await downloader.getTtsDir();
        final piperDir = '${ttsDir.path}/piper';
        if (!await Directory(piperDir).exists()) {
          throw StateError('Piper models directory not found.');
        }
        modelPath = piperDir;
        break;
      default:
        return;
    }

    _initCompleter = Completer<void>();
    _workerSendPort!.send(
      TtsInitRequest(
        engineId: engineId,
        modelPath: modelPath,
        voicesPath: voicesPath,
        espeakPath: resolvedEspeakPath,
      ),
    );

    await _initCompleter!.future;
    _currentEngine = engineId;
    _isWorkerInitializing = false;
  }

  Future<void> speak(String text, {EngineId? engineId, String? voiceId}) async {
    if (text.trim().isEmpty) return;

    _isStopping = false;
    if (state.isSpeaking) {
      await stop();
      // Wait a bit for the player to fully stop
      await Future.delayed(const Duration(milliseconds: 100));
      _isStopping = false;
    }

    final settings = ref.read(settingsProvider);
    engineId ??= settings.ttsEngine;

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
        state = state.copyWith(isSpeaking: false, playingContent: null);
      }
      return;
    }

    _chunks = _splitText(text);
    _currentChunkIndex = 0;
    _currentVoice = voiceId;
    _synthesizedChunks.clear();
    _lastEnqueuedChunk = -1;
    _currentSessionId++;

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
      await _playNextChunk();
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

  Future<void> _playNextChunk() async {
    if (_isStopping || _currentChunkIndex >= _chunks.length) return;

    // Start synthesizing more chunks
    _enqueueNextChunks();

    // Check if current chunk is synthesized
    if (!_synthesizedChunks.containsKey(_currentChunkIndex)) {
      Log.debug('Waiting for chunk $_currentChunkIndex to be synthesized...');
      return;
    }

    final wavBytes = _synthesizedChunks[_currentChunkIndex]!;
    _synthesizedChunks.remove(_currentChunkIndex); // Clear memory

    try {
      Log.debug(
        'Playing chunk ${_currentChunkIndex + 1}/${_chunks.length}: "${_chunks[_currentChunkIndex]}"',
      );

      await _player.stop();
      await _player.setSource(BytesSource(wavBytes));
      await _player.resume();
    } catch (e) {
      Log.error('Error playing chunk $_currentChunkIndex: $e');
      _onChunkFinished();
    }
  }

  void _enqueueNextChunks() {
    if (_workerSendPort == null || _currentEngine == null) return;

    final settings = ref.read(settingsProvider);
    final availableVoices = voicesForEngine(_currentEngine!);
    final voiceId =
        _currentVoice ??
        settings.ttsVoiceId ??
        (availableVoices.isNotEmpty ? availableVoices.first.id : 'Luna');

    while (_lastEnqueuedChunk < _chunks.length - 1 &&
        _lastEnqueuedChunk < _currentChunkIndex + _lookAheadCount) {
      _lastEnqueuedChunk++;
      final chunkIndex = _lastEnqueuedChunk;
      final text = _chunks[chunkIndex];

      Log.debug('Enqueuing synthesis for chunk $chunkIndex');
      _workerSendPort!.send(
        TtsSynthesizeRequest(
          text: text,
          voiceId: voiceId,
          speed: settings.ttsSpeed,
          chunkIndex: chunkIndex,
          sessionId: _currentSessionId,
        ),
      );
    }
  }

  Future<void> stop() async {
    _isStopping = true;
    if (_isPlayerDisposed) return;
    try {
      await _player.stop();
      // Don't release here, as it makes restarting slower and can cause state issues
    } catch (_) {}
    await _flutterTts?.stop();
    state = state.copyWith(
      isSpeaking: false,
      isInitializing: false,
      playingContent: null,
    );
  }

  Future<void> previewVoice(Voice voice) async {
    await speak(ttsPreviewSample, engineId: voice.engine, voiceId: voice.id);
  }
}

const ttsPreviewSample = "Hello, this is a preview of the selected voice.";
