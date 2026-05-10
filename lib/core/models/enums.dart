enum EngineId { system, kitten, kokoro, piper }

class EngineMeta {
  final String name;
  final String tagline;
  final int sizeMb;
  final int ramMb;
  final int voiceCount;
  final int accentColor;

  const EngineMeta({
    required this.name,
    required this.tagline,
    required this.sizeMb,
    required this.ramMb,
    required this.voiceCount,
    required this.accentColor,
  });

  static const system = EngineMeta(
    name: 'System TTS',
    tagline: 'Built-in device engine',
    sizeMb: 0,
    ramMb: 0,
    voiceCount: 0,
    accentColor: 0xFF9E9E9E,
  );

  static const kitten = EngineMeta(
    name: 'Kitten TTS',
    tagline: 'High-speed neural TTS',
    sizeMb: 57,
    ramMb: 120,
    voiceCount: 8,
    accentColor: 0xFFFF9800,
  );

  static const kokoro = EngineMeta(
    name: 'Kokoro TTS',
    tagline: 'Premium neural voices',
    sizeMb: 170,
    ramMb: 250,
    voiceCount: 22,
    accentColor: 0xFFE91E63,
  );

  static const piper = EngineMeta(
    name: 'Piper TTS',
    tagline: 'Open-source neural voices',
    sizeMb: 50,
    ramMb: 100,
    voiceCount: 2,
    accentColor: 0xFF4CAF50,
  );

  static EngineMeta forEngine(EngineId engine) {
    switch (engine) {
      case EngineId.kitten:
        return kitten;
      case EngineId.kokoro:
        return kokoro;
      case EngineId.piper:
        return piper;
      default:
        return system;
    }
  }
}

class Voice {
  final String id;
  final String name;
  final EngineId engine;
  final String? language;
  final String gender;

  const Voice({
    required this.id,
    required this.name,
    required this.engine,
    this.language,
    required this.gender,
  });
}

List<Voice> voicesForEngine(EngineId engine) {
  switch (engine) {
    case EngineId.kitten:
      return kittenVoices;
    case EngineId.kokoro:
      return kokoroVoices;
    case EngineId.piper:
      return piperVoices;
    default:
      return [];
  }
}

const List<Voice> kittenVoices = [
  Voice(id: 'Bella', name: 'Bella', engine: EngineId.kitten, language: 'en', gender: 'f'),
  Voice(id: 'Jasper', name: 'Jasper', engine: EngineId.kitten, language: 'en', gender: 'm'),
  Voice(id: 'Luna', name: 'Luna', engine: EngineId.kitten, language: 'en', gender: 'f'),
  Voice(id: 'Bruno', name: 'Bruno', engine: EngineId.kitten, language: 'en', gender: 'm'),
  Voice(id: 'Rosie', name: 'Rosie', engine: EngineId.kitten, language: 'en', gender: 'f'),
  Voice(id: 'Hugo', name: 'Hugo', engine: EngineId.kitten, language: 'en', gender: 'm'),
  Voice(id: 'Kiki', name: 'Kiki', engine: EngineId.kitten, language: 'en', gender: 'f'),
  Voice(id: 'Leo', name: 'Leo', engine: EngineId.kitten, language: 'en', gender: 'm'),
];

const List<Voice> kokoroVoices = [
  Voice(id: 'af_heart', name: 'Heart', engine: EngineId.kokoro, language: 'en', gender: 'f'),
  Voice(id: 'af_bella', name: 'Bella', engine: EngineId.kokoro, language: 'en', gender: 'f'),
  Voice(id: 'af_nicole', name: 'Nicole', engine: EngineId.kokoro, language: 'en', gender: 'f'),
  Voice(id: 'af_aoihana', name: 'Aoihana', engine: EngineId.kokoro, language: 'en', gender: 'f'),
  Voice(id: 'af_sarah', name: 'Sarah', engine: EngineId.kokoro, language: 'en', gender: 'f'),
  Voice(id: 'af_sky', name: 'Sky', engine: EngineId.kokoro, language: 'en', gender: 'f'),
  Voice(id: 'am_adam', name: 'Adam', engine: EngineId.kokoro, language: 'en', gender: 'm'),
  Voice(id: 'am_michael', name: 'Michael', engine: EngineId.kokoro, language: 'en', gender: 'm'),
  Voice(id: 'bf_isabelle', name: 'Isabelle', engine: EngineId.kokoro, language: 'en', gender: 'f'),
  Voice(id: 'bf_alice', name: 'Alice', engine: EngineId.kokoro, language: 'en', gender: 'f'),
  Voice(id: 'bm_george', name: 'George', engine: EngineId.kokoro, language: 'en', gender: 'm'),
  Voice(id: 'bm_lewis', name: 'Lewis', engine: EngineId.kokoro, language: 'en', gender: 'm'),
];

const List<Voice> piperVoices = [
  Voice(id: 'en_US-lessac-medium', name: 'Lessac (US)', engine: EngineId.piper, language: 'en', gender: 'f'),
  Voice(id: 'en_US-ryan-medium', name: 'Ryan (US)', engine: EngineId.piper, language: 'en', gender: 'm'),
];

enum ServerType { lmStudio, openAICompatible, ollama, openRouter, onDevice }

enum ConnectionStatus { connected, disconnected, checking, error }

enum MessageRole { user, assistant, system, tool }

enum MessageStatus { sending, streaming, complete, error }

enum ModelStatus { unloaded, loading, loaded, preloaded, thinking }

enum OnDeviceEngineStatus { notLoaded, loading, loaded, error }

enum LiteLmBackendType { cpu, gpu, npu }

EngineId engineIdFromString(String value) {
  switch (value) {
    case 'kitten':
      return EngineId.kitten;
    case 'kokoro':
      return EngineId.kokoro;
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
