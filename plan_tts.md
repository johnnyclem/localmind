# Feature Plan: On-Device Neural TTS for Flutter

## Overview

Port the PocketPal AI TTS system to a Flutter app. The system uses **on-device neural TTS engines** (no cloud APIs) orchestrated through a custom native module. All model files are downloaded at runtime from HuggingFace and run locally via ONNX Runtime.

---

## Architecture

### High-Level Layers

```
┌──────────────────────────────────────────────────┐
│  UI Layer (Flutter widgets)                       │
│  - TTSSetupSheet (engine cards, voice picker)     │
│  - PlayButton, VoiceChip                          │
│  - AutoSpeakRow, HeroRow (quality selector)       │
└──────────────────────┬───────────────────────────┘
                       │ calls
┌──────────────────────▼───────────────────────────┐
│  TTS Store (State Management)                     │
│  - orchestrates playback, download lifecycle      │
│  - per-engine download state machines             │
│  - streaming vs replay paths                      │
│  - memory gate (4 GiB minimum RAM)               │
│  - thinking stripper for LLM <think> tags         │
└──────────────────────┬───────────────────────────┘
                       │ calls
┌──────────────────────▼───────────────────────────┐
│  TTS Runtime (singleton coordinator)              │
│  - serializes engine swap (only 1 engine at a time)│
│  - acquire/release lifecycle                      │
│  - stop ordering via mutex chain                  │
└──────────────────────┬───────────────────────────┘
                       │ calls
┌──────────────────────▼───────────────────────────┐
│  Engine Implementations                           │
│  ┌─────────┬──────────┬────────────┬──────────┐  │
│  │ Kitten  │ Kokoro   │ Supertonic │ System   │  │
│  │ (nano)  │ (medium) │ (large)    │ (OS TTS) │  │
│  └─────────┴──────────┴────────────┴──────────┘  │
└──────────────────────┬───────────────────────────┘
                       │ calls
┌──────────────────────▼───────────────────────────┐
│  Flutter Native Module (platform channel)         │
│  - ONNX Runtime inference                         │
│  - Phonemizer (grapheme→IPA conversion)           │
│  - Audio playback                                 │
└──────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **No cloud APIs** — all TTS runs on-device using neural ONNX models
2. **Single active engine** — only one neural engine loaded at a time (saves RAM)
3. **CPU-only execution** — `executionProviders: 'cpu'` for battery/thermal stability
4. **4 GiB RAM minimum gate** — TTS disabled on devices with <4GB total RAM
5. **Phonemization required** for Kokoro and Kitten engines (grapheme→IPA)

---

## TTS Engines

### Engine Comparison Table

| Feature | Kitten | Kokoro | Supertonic | System |
|---------|--------|--------|------------|--------|
| Type | StyleTTS2 nano | Kokoro 82M v1.0 | Supertonic v2 | OS native |
| Format | ONNX FP32 | ONNX FP16 | ONNX (5 files) | Platform API |
| Disk | ~57 MB | ~170 MB | ~265 MB | 0 MB |
| RAM (peak) | ~235 MB | ~510 MB | ~428 MB | Minimal |
| Voices | 8 (4F/4M) | 22 (17F/5M) | 10 (5F/5M) | OS-dependent |
| Languages | EN only | EN, EN-GB | EN, KO, ES, PT, FR | OS-dependent |
| Phonemizer? | Yes (JS `phonemize`) | Yes (JS `phonemize`) | No (grapheme direct) | No |
| Install | One-phase (all-or-nothing) | Two-phase (core + voices) | Two-phase (core + voices) | Always available |
| Voice embeddings | Built-in NPZ | Per-voice `.bin` files | Per-voice `.json` style files | OS built-in |

### Model Sources (HuggingFace)

- **IPA dictionary (shared):** `https://huggingface.co/datasets/palshub/phonemizer-dicts/resolve/main/en-us.bin` → saved as `en-us.bin`
- **Kitten:** `https://huggingface.co/palshub/kitten-tts-nano-0.8-fp32`
  - Files: `kitten_tts_nano_v0_8.onnx` → `kitten.onnx`, `voices-manifest.json`
- **Kokoro:** `https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX`
  - Core: `onnx/model_fp16.onnx` → `model.onnx`, `tokenizer.json`
  - Voices: per-voice `.bin` files under `voices/` directory
- **Supertonic:** `https://huggingface.co/Supertone/supertonic-2`
  - 5 ONNX files: `duration_predictor.onnx`, `text_encoder.onnx`, `vector_estimator.onnx`, `vocoder.onnx`, `unicode_indexer.json`
  - Voices: per-voice `.json` files under `voice_styles/`

---

## Phonemizer

### Why It's Needed

Kokoro and Kitten are **phoneme-based** TTS models: they accept IPA phonemes as input, not raw text. The text must be converted to phonemes before synthesis.

### Implementation

- **Library:** MIT `phonemize` JS library (v1.1.0)
- **Input:** Grapheme text (e.g., "Hello world")
- **Output:** IPA phoneme sequence (e.g., "həlˈoʊ wˈɜːld")
- **Dictionary:** Pre-built `en-us.bin` IPA dictionary (~XX MB), downloaded from HuggingFace
- **How it flows:**
  1. User text is received by the engine
  2. Text is chunked (max 200 chars per batch)
  3. Each chunk is passed through `phonemize(text_chunk)`
  4. Phoneme sequence is fed to the ONNX model for synthesis
  5. ONNX output → audio waveform → playback

### Flutter Port

In the React Native version, phonemization happens inside the native `@pocketpalai/react-native-speech` module. For Flutter, you have **two options:**

**Option A: Dart phonemizer (recommended)**
- Port the MIT `phonemize` JS library to Dart
- Bundle the `en-us.bin` IPA dictionary (download at runtime from HuggingFace)
- Run phonemization in Dart before passing phonemes to native

**Option B: Native phonemizer**
- Implement phonemization in the platform channel (Kotlin/Swift)
- Use the `phonemize` JS library via a JS engine (requires embedding QuickJS/JSC)
- Or use another native phonemizer (e.g., `espeak-ng` bindings — but this adds ~15 MB)

**Recommendation:** Option A — pure Dart phonemizer keeps the port clean and avoids native complexity.

---

## Directory Structure (App Documents)

```
<app_documents>/
└── tts/
    ├── en-us.bin                          # IPA dict (shared)
    ├── kitten/
    │   ├── kitten.onnx
    │   ├── voices-manifest.json
    │   └── en-us.bin
    ├── kokoro/
    │   ├── model.onnx
    │   ├── tokenizer.json
    │   ├── voices-manifest.json
    │   ├── en-us.bin
    │   └── voices/
    │       ├── af_heart.bin
    │       ├── af_bella.bin
    │       └── ...
    └── supertonic/
        ├── duration_predictor.onnx
        ├── text_encoder.onnx
        ├── vector_estimator.onnx
        ├── vocoder.onnx
        ├── unicode_indexer.json
        ├── voices-manifest.json
        ├── F1.json
        ├── F2.json
        └── ...
```

**iOS:** Root path is `Library/Application Support/tts/` (excluded from iCloud backup via `NSURLIsExcludedFromBackupKey`)
**Android:** Root path is `files/tts/` (excluded from backup via backup rules XML)

---

## Voice Catalogs

### Voice Type Definition

```dart
enum EngineId { kitten, kokoro, supertonic, system }

class Voice {
  final String id;
  final String name;
  final EngineId engine;
  final String? language;
  final String? gender; // 'f' or 'm'
}
```

### Kitten (8 voices)

| ID | Name | Gender |
|----|------|--------|
| `expr-voice-2-f` | Bella | f |
| `expr-voice-3-f` | Luna | f |
| `expr-voice-4-f` | Rosie | f |
| `expr-voice-5-f` | Kiki | f |
| `expr-voice-2-m` | Jasper | m |
| `expr-voice-3-m` | Bruno | m |
| `expr-voice-4-m` | Hugo | m |
| `expr-voice-5-m` | Leo | m |

### Kokoro (22 voices)

American English female: `af_heart` (Heart), `af_bella` (Bella), `af_nicole` (Nicole), `af_sarah` (Sarah), `af_sky` (Sky), `af_aoede` (Aoede), `af_jessica` (Jessica), `af_kore` (Kore), `af_river` (River)
American English male: `am_adam` (Adam), `am_echo` (Echo), `am_eric` (Eric), `am_fenrir` (Fenrir), `am_liam` (Liam), `am_michael` (Michael), `am_onyx` (Onyx), `am_santa` (Santa)
British English female: `bf_alice` (Alice), `bf_emma` (Emma), `bf_lily` (Lily)
British English male: `bm_george` (George), `bm_lewis` (Lewis)

### Supertonic (10 voices)

Female: `F1` (Sarah), `F2` (Lily), `F3` (Jessica), `F4` (Olivia), `F5` (Emily)
Male: `M1` (Alex), `M2` (James), `M3` (Robert), `M4` (Sam), `M5` (Daniel)

---

## Core Interfaces to Implement

### Engine Interface

```dart
abstract class Engine {
  EngineId get id;
  Future<bool> isInstalled();
  Future<List<Voice>> getVoices();
  Future<void> loadInto();     // Initialize native engine
  Future<void> play(String text, Voice voice);
  StreamingHandle playStreaming(Voice voice, [Future<void>? waitFor]);
  Future<void> stop();
}
```

### StreamingHandle

```dart
abstract class StreamingHandle {
  void appendText(String chunk);
  Future<void> finalize();
  Future<void> cancel();
}
```

### TTSRuntime (Singleton)

- Tracks which engine is currently loaded in native land
- Serializes all engine swaps via a promise chain (FIFO mutex)
- `acquire(engine, fn)` — releases previous engine, loads new one, runs fn
- `release()` — frees native resources
- `stop()` — stops playback AND serializes with subsequent acquires

### TTSStore (State)

- **Persisted preferences:** `autoSpeakEnabled`, `currentVoice`, `supertonicSteps`
- **Non-persisted state:** per-engine `NeuralDownloadState` (not_installed / downloading / ready / error), download progress, playback state
- **Streaming hooks:** `onAssistantMessageStart`, `onAssistantMessageChunk`, `onAssistantMessageComplete`
- **Replay path:** `play(messageId, text)`
- **Preview path:** `preview(voice)`
- **Download actions:** `downloadSupertonic()`, `downloadKokoro()`, `downloadKitten()`, plus retry/delete variants

---

## Download Lifecycle

### Kitten (one-phase, all-or-nothing)

```
1. mkdir tts/kitten/ (with iOS backup exclusion on parent)
2. Download kitten.onnx (progress tracked)
3. Download voices-manifest.json (progress tracked)
4. Download en-us.bin IPA dict (progress tracked)
5. If ANY step fails: delete entire tts/kitten/ directory
6. On success: set download state to 'ready'
```

### Kokoro (two-phase)

```
Phase 1 (all-or-nothing, 60% of progress weight):
  1. mkdir tts/kokoro/voices/
  2. Download model.onnx
  3. Download tokenizer.json
  4. Download en-us.bin
  5. If ANY fails: delete entire tts/kokoro/

Phase 2 (best-effort, 40% of progress weight):
  6. Download each voice's .bin embedding file
  7. Partial success OK (missing voice files fetched lazily later)
  8. Write voices-manifest.json pointing at voices/ directory
```

### Supertonic (two-phase)

```
Phase 1 (all-or-nothing, 70% of progress weight):
  1. mkdir tts/supertonic/
  2. Download duration_predictor.onnx
  3. Download text_encoder.onnx
  4. Download vector_estimator.onnx
  5. Download vocoder.onnx
  6. Download unicode_indexer.json
  7. If ANY fails: delete entire tts/supertonic/

Phase 2 (best-effort, 30% of progress weight):
  8. Download each voice's .json style file
  9. Write voices-manifest.json with baseUrl for lazy fallback
```

---

## Playback Paths

### Streaming Path (during LLM response)

```
1. onAssistantMessageStart(messageId)
   - Stop any prior playback
   - Create ThinkingStripper instance
   - Get engine for currentVoice
   - acquire(engine): release old engine → loadInto() new engine
   - Create SpeechStream (native)
   - Return StreamingHandle

2. onAssistantMessageChunk(chunk, reasoningDelta?)
   - Feed chunk to ThinkingStripper (strips <think>...</think>)
   - If thinking detected → prepend "Hmm, let me think." placeholder
   - Append cleaned text to StreamingHandle
   - (Native phonemizes and synthesizes incrementally)

3. onAssistantMessageComplete(text)
   - Flush ThinkingStripper leftovers
   - StreamingHandle.finalize()
```

### Replay Path (play button on past message)

```
1. stop() any in-flight playback
2. Strip <think> tags via ThinkingStripper.stripFinal(text)
3. Prepend thinking placeholder if reasoning occurred
4. play() → acquire(engine) → Speech.speak(phonemized_text, voiceId)
5. On completion → set playbackState to idle
```

---

## Thinking/Reasoning Stripper

### Purpose

LLM responses may contain `<think>...</think>` tags (either from the model or from a separate `reasoning_content` stream). These should be stripped before TTS to avoid speaking internal reasoning aloud.

### Implementation

```dart
class ThinkingStripper {
  String _buffer = '';
  bool _inside = false;
  bool _nonEmptyThink = false;

  // Feed a chunk, return clean text to speak
  String feed(String chunk);

  // Flush remaining buffer at stream end
  String flush();

  // Whether non-empty think content was encountered
  bool hadNonEmptyThink();

  // Record out-of-band reasoning delta
  void noteReasoning(String delta);

  // Static helper for non-streaming replay
  static StripResult stripFinal(String text, {bool? hadReasoning});
}
```

**Placeholder phrases** (randomly selected): "Hmm, let me think.", "Hmm.", "Let me think.", "Okay, let me think about that.", "One moment.", "Let me consider this."

---

## Voice Selection Flow (UI)

1. User opens `TTSSetupSheet` bottom sheet
2. Sees engine cards in order: Kitten → Kokoro → Supertonic
3. Each card shows: engine logo, name, tagline, disk size, RAM, voice count, accent color
4. Uninstalled engine: shows "Install · XX MB" button with progress bar during download
5. Installed engine: expandable to show voice radio buttons grouped by gender
6. Tapping a voice: calls `ttsStore.currentVoice = voice` (persisted)
7. Preview button plays `TTS_PREVIEW_SAMPLE` text through selected voice
8. Quality selector (Supertonic only): diffusion steps `1/2/3/5/10/20`

### Engine Metadata for UI

```dart
class EngineMeta {
  final int sizeMb;
  final int ramMb;
  final int voices;
  final String accent;
  final String gradientFrom;
  final String gradientTo;
}
```

| Engine | Size | RAM | Voices | Accent |
|--------|------|-----|--------|--------|
| Kitten | 57 MB | 235 MB | 8 | #F29547 |
| Kokoro | 170 MB | 510 MB | 22 | #6F5CD6 |
| Supertonic | 265 MB | 428 MB | 10 | #1E4DF6 |

---

## Native Module Platform Channel API

The Flutter app needs a native platform channel (MethodChannel) with these methods:

### Initialization

```dart
// Kitten
await platform.invokeMethod('tts.initialize', {
  'engine': 'kitten',
  'modelPath': '/path/to/kitten.onnx',
  'voicesPath': '/path/to/voices-manifest.json',
  'dictPath': '/path/to/en-us.bin',
  'executionProviders': 'cpu',
  'maxChunkSize': 200,
  'silentMode': 'obey',
  'ducking': true,
});

// Kokoro
await platform.invokeMethod('tts.initialize', {
  'engine': 'kokoro',
  'modelPath': '/path/to/model.onnx',
  'tokenizerPath': '/path/to/tokenizer.json',
  'voicesPath': '/path/to/voices-manifest.json',
  'dictPath': '/path/to/en-us.bin',
  'executionProviders': 'cpu',
  'maxChunkSize': 200,
  'silentMode': 'obey',
  'ducking': true,
});

// Supertonic
await platform.invokeMethod('tts.initialize', {
  'engine': 'supertonic',
  'durationPredictorPath': '/path/to/duration_predictor.onnx',
  'textEncoderPath': '/path/to/text_encoder.onnx',
  'vectorEstimatorPath': '/path/to/vector_estimator.onnx',
  'vocoderPath': '/path/to/vocoder.onnx',
  'unicodeIndexerPath': '/path/to/unicode_indexer.json',
  'voicesPath': '/path/to/voices-manifest.json',
  'executionProviders': 'cpu',
  'maxChunkSize': 200,
  'silentMode': 'obey',
  'ducking': true,
});

// System (OS native)
await platform.invokeMethod('tts.initialize', {
  'engine': 'os_native',
});
```

### Playback

```dart
// Non-streaming speak
await platform.invokeMethod('tts.speak', {
  'text': 'Hello world',       // Pre-phonemized text for Kitten/Kokoro
  'voiceId': 'af_bella',
  'language': 'en',             // Supertonic only
  'inferenceSteps': 5,          // Supertonic only
});

// Create speech stream
final stream = EventChannel('tts.stream.$voiceId');
// Send chunks via MethodChannel
await platform.invokeMethod('tts.stream.append', {'text': 'chunk'});
await platform.invokeMethod('tts.stream.finalize');
await platform.invokeMethod('tts.stream.cancel');

// Control
await platform.invokeMethod('tts.stop');
await platform.invokeMethod('tts.release');

// System voices
final voices = await platform.invokeMethod('tts.getAvailableVoices');
```

### OS-Specific Notes

**iOS:**
- Use `AVSpeechSynthesizer` for System engine
- Neural engines: ONNX Runtime with CoreML execution provider (optional, CPU is safer)
- Model storage: `NSLibraryDirectory/Application Support/tts/` with backup exclusion
- Handle audio session interruptions

**Android:**
- Use `TextToSpeech` API for System engine
- Neural engines: ONNX Runtime with NNAPI (optional, CPU is safer)
- Model storage: `context.filesDir/tts/` with backup rules in `AndroidManifest.xml`
- Handle `TextToSpeech.OnInitListener` for System engine

---

## Implementation Order

### Phase 1: Foundation
1. Create Dart `Engine` interface and `Voice` types
2. Implement `TTSRuntime` singleton with serialized acquire/release
3. Create `ThinkingStripper` in Dart
4. Implement platform channel for System engine (OS native TTS)
5. Build basic `TTSStore` with `play()` replay path
6. Verify System engine works on both platforms

### Phase 2: Neural Engine Support
7. Implement file download infrastructure (resumable, progress tracking)
8. Build native module boilerplate for ONNX Runtime (Kotlin/Swift)
9. Implement Kitten engine (simplest — single phase, 8 voices)
10. Implement Kokoro engine (two-phase, 22 voices, phonemizer needed)
11. Implement Supertonic engine (5 ONNX files, multilingual)
12. Implement per-engine download state machines in `TTSStore`

### Phase 3: Streaming
13. Implement `StreamingHandle` in Dart
14. Implement `SpeechStream` in native (Kotlin/Swift)
15. Wire streaming path through `TTSStore` (`onAssistantMessageStart/Chunk/Complete`)
16. Integrate with LLM chat session

### Phase 4: UI
17. Build `TTSSetupSheet` bottom sheet widget
18. Build `EngineCard` widget with install/delete controls
19. Build `VoicePickerView` with gender-grouped radio buttons
20. Build `PlayButton` for per-message replay
21. Build `VoiceChip` header pill
22. Build `AutoSpeakRow` toggle
23. Build `HeroRow` quality selector (Supertonic steps)

### Phase 5: Polish
24. Implement RAM gate check (`DeviceInfo.getTotalMemory()` → min 4 GiB)
25. iOS backup exclusion on `tts/` directory
26. Handle app backgrounding (release engine resources)
27. Handle audio interruptions (phone calls, etc.)
28. Disk space check before download
29. Handle model deletion cleanup
30. Error states and retry flows

---

## Constants Reference

```dart
// Preview sample
const ttsPreviewSample = "Oh, hello there! I've been waiting for you to test me. I sound pretty good!";

// RAM gate
const ttsMinRamBytes = 4 * 1024 * 1024 * 1024; // 4 GiB

// Directories
const ttsParentSubdir = 'tts';
const kittenModelSubdir = 'tts/kitten';
const kokoroModelSubdir = 'tts/kokoro';
const supertonicModelSubdir = 'tts/supertonic';

// Model URLs
const ttsDictUrl = 'https://huggingface.co/datasets/palshub/phonemizer-dicts/resolve/main/en-us.bin';
const kittenModelBaseUrl = 'https://huggingface.co/palshub/kitten-tts-nano-0.8-fp32/resolve/main';
const kokoroModelBaseUrl = 'https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main';
const supertonicModelBaseUrl = 'https://huggingface.co/Supertone/supertonic-2/resolve/main';

// Engine config
const maxChunkSize = 200;
const streamTargetChars = 300;
const supertonicStepsDefault = 5;
```

---

## Testing Strategy

- Unit test `ThinkingStripper` with various `<think>` tag patterns
- Unit test `TTSRuntime` acquire/release/stop ordering
- Unit test `TTSStore` state machine transitions
- Widget test engine cards in various states (not_installed, downloading, ready, error)
- Integration test download → initialize → play flow for each engine
- Integration test streaming path with mock LLM token feed
- Test edge cases: switching engines mid-playback, rapid play/stop cycles, app backgrounding mid-download
- Test on low-RAM devices (verify gate disables TTS)
- Test on iOS and Android with all 4 engines

---

## Key Source Files (Reference)

From the original React Native codebase (`src/services/tts/`):

| File | Purpose |
|------|---------|
| `types.ts` | Core types: `Engine`, `Voice`, `StreamingHandle`, `EngineId` |
| `constants.ts` | Model URLs, file names, sizes, config constants |
| `runtime.ts` | `TTSRuntime` singleton — serialized engine swap |
| `engineRegistry.ts` | Singleton instances of all 4 engines |
| `streamingHandle.ts` | `createEngineStreamingHandle()` — bridges streaming with runtime |
| `thinkingStripper.ts` | `ThinkingStripper` class for `<think>` tag stripping |
| `engines/kitten/index.ts` | Kitten engine implementation |
| `engines/kitten/voices.ts` | Kitten voice catalog |
| `engines/kokoro/index.ts` | Kokoro engine implementation |
| `engines/kokoro/voices.ts` | Kokoro voice catalog |
| `engines/supertonic/index.ts` | Supertonic engine implementation |
| `engines/supertonic/voices.ts` | Supertonic voice catalog |
| `engines/system/index.ts` | System engine implementation |
| `engines/system/voices.ts` | System voice fetcher |
| `store/TTSStore.ts` | Main TTS store with all orchestration |
| `components/TTSSetupSheet/engineMeta.ts` | Per-engine UI metadata |
