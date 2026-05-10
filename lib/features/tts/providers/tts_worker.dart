import 'dart:isolate';
import 'dart:typed_data';
import 'package:meomeo/meomeo.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';

sealed class TtsWorkerMessage {}

class TtsInitRequest extends TtsWorkerMessage {
  final EngineId engineId;
  final String modelPath;
  final String voicesPath;
  final String espeakPath;

  TtsInitRequest({
    required this.engineId,
    required this.modelPath,
    required this.voicesPath,
    required this.espeakPath,
  });
}

class TtsSynthesizeRequest extends TtsWorkerMessage {
  final String text;
  final String voiceId;
  final double speed;
  final int chunkIndex;
  final int sessionId;

  TtsSynthesizeRequest({
    required this.text,
    required this.voiceId,
    required this.speed,
    required this.chunkIndex,
    required this.sessionId,
  });
}

class TtsStopRequest extends TtsWorkerMessage {}

class TtsWorkerResponse {
  final int? chunkIndex;
  final int? sessionId;
  final Uint8List? wavBytes;
  final String? error;
  final bool isInitResponse;

  TtsWorkerResponse({
    this.chunkIndex,
    this.sessionId,
    this.wavBytes,
    this.error,
    this.isInitResponse = false,
  });
}

void ttsWorkerEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  MeoKitten? kitten;
  MeoKokoro? kokoro;
  MeoPiper? piper;
  EngineId? activeEngineId;

  receivePort.listen((message) async {
    try {
      if (message is TtsInitRequest) {
        // Dispose old engines
        try {
          kitten?.dispose();
          kokoro?.dispose();
          piper?.dispose();
        } catch (_) {}
        kitten = null;
        kokoro = null;
        piper = null;

        activeEngineId = message.engineId;
        switch (message.engineId) {
          case EngineId.kitten:
            kitten = MeoKitten(
              model: message.modelPath,
              voices: message.voicesPath,
              espeakData: message.espeakPath,
            );
            break;
          case EngineId.kokoro:
            kokoro = MeoKokoro(
              model: message.modelPath,
              voices: message.voicesPath,
              espeakData: message.espeakPath,
            );
            break;
          case EngineId.piper:
            piper = MeoPiper.dir(
              path: message.modelPath,
              espeakData: message.espeakPath,
            );
            break;
          default:
            Log.warning('Unknown engine ID: ${message.engineId}');
            break;
        }
        Log.info('Worker initialized engine: ${message.engineId}');
        mainSendPort.send(TtsWorkerResponse(isInitResponse: true));
      } else if (message is TtsSynthesizeRequest) {
        if (activeEngineId == null) {
          mainSendPort.send(TtsWorkerResponse(
            chunkIndex: message.chunkIndex,
            sessionId: message.sessionId,
            error: 'No engine initialized in worker',
          ));
          return;
        }

        final speaker = Speaker(voice: message.voiceId, speed: message.speed);
        Float32List? pcm;
        int sampleRate = 22050;

        if (activeEngineId == EngineId.kitten) {
          Log.debug('Worker synthesis with Kitten: "${message.text}"');
          pcm = await kitten?.speak(message.text, speaker: speaker);
          sampleRate = 24000;
        } else if (activeEngineId == EngineId.kokoro) {
          Log.debug('Worker synthesis with Kokoro: "${message.text}"');
          pcm = await kokoro?.speak(message.text, speaker: speaker);
          sampleRate = 24000;
        } else if (activeEngineId == EngineId.piper) {
          Log.debug('Worker synthesis with Piper: "${message.text}"');
          pcm = await piper?.speak(message.text, speaker: speaker);
          sampleRate = 22050;
        }

        if (pcm != null && pcm.isNotEmpty) {
          Log.debug('Worker synthesis success: ${pcm.length} samples');
          final wavBytes = _createWav(pcm, sampleRate);
          mainSendPort.send(TtsWorkerResponse(
            chunkIndex: message.chunkIndex,
            sessionId: message.sessionId,
            wavBytes: wavBytes,
          ));
        } else {
          final err = pcm == null ? 'Synthesis returned null' : 'Empty PCM generated';
          Log.error('Worker synthesis failed for chunk ${message.chunkIndex}: $err');
          mainSendPort.send(TtsWorkerResponse(
            chunkIndex: message.chunkIndex,
            sessionId: message.sessionId,
            error: err,
          ));
        }
      } else if (message is TtsStopRequest) {
        // Handled by main thread by clearing its own queue, 
        // but we could use this to cancel current synthesis if meomeo supported it.
      }
    } catch (e) {
      mainSendPort.send(TtsWorkerResponse(error: e.toString()));
    }
  });
}

Uint8List _createWav(Float32List samples, int sampleRate) {
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
