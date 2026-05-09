import 'package:neural_tts/neural_tts.dart';

enum ServerType { lmStudio, openAICompatible, ollama, openRouter, onDevice }

enum ConnectionStatus { connected, disconnected, checking, error }

enum MessageRole { user, assistant, system, tool }

enum MessageStatus { sending, streaming, complete, error }

enum ModelStatus { unloaded, loading, loaded, preloaded, thinking }

enum OnDeviceEngineStatus { notLoaded, loading, loaded, error }

enum LiteLmBackendType { cpu, gpu, npu }

enum KittenTtsVoice {
  bella,
  jasper,
  luna,
  bruno,
  rosie,
  hugo,
  kiki,
  leo;

  String get displayName {
    switch (this) {
      case KittenTtsVoice.bella:
        return 'Bella';
      case KittenTtsVoice.jasper:
        return 'Jasper';
      case KittenTtsVoice.luna:
        return 'Luna';
      case KittenTtsVoice.bruno:
        return 'Bruno';
      case KittenTtsVoice.rosie:
        return 'Rosie';
      case KittenTtsVoice.hugo:
        return 'Hugo';
      case KittenTtsVoice.kiki:
        return 'Kiki';
      case KittenTtsVoice.leo:
        return 'Leo';
    }
  }

  String get id {
    switch (this) {
      case KittenTtsVoice.bella:
        return 'expr-voice-2-f';
      case KittenTtsVoice.jasper:
        return 'expr-voice-2-m';
      case KittenTtsVoice.luna:
        return 'expr-voice-3-f';
      case KittenTtsVoice.bruno:
        return 'expr-voice-3-m';
      case KittenTtsVoice.rosie:
        return 'expr-voice-4-f';
      case KittenTtsVoice.hugo:
        return 'expr-voice-4-m';
      case KittenTtsVoice.kiki:
        return 'expr-voice-5-f';
      case KittenTtsVoice.leo:
        return 'expr-voice-5-m';
    }
  }
}

EngineId engineIdFromString(String value) {
  switch (value) {
    case 'kitten':
      return EngineId.kitten;
    case 'kokoro':
      return EngineId.kokoro;
    case 'supertonic':
      return EngineId.supertonic;
    default:
      return EngineId.system;
  }
}

Voice? voiceFromSettings(String? voiceId, EngineId engine) {
  if (voiceId == null || voiceId.isEmpty) return null;
  final voices = voicesForEngine(engine);
  try {
    return voices.firstWhere((v) => v.id == voiceId);
  } catch (_) {
    return null;
  }
}

enum OnDeviceModelState {
  notDownloaded,
  downloading,
  downloaded,
  loading,
  loaded,
  error,
}
