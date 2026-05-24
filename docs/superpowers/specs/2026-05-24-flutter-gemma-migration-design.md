# Migration: flutter_litert_lm to flutter_gemma

**Date:** 2026-05-24
**Status:** Approved
**Scope:** Replace on-device inference engine and model management with flutter_gemma for cross-platform support and better performance/stability.

## Goals

1. Replace `flutter_litert_lm` with `flutter_gemma` ^0.16.1
2. Enable on-device inference on Android and iOS (desktop platforms deferred)
3. Use flutter_gemma's built-in model download/management system
4. Maintain existing UX patterns (model manager, chat streaming, backend selection)

## Non-Goals

- Adding multimodal (vision/audio) support in this migration
- Adding function calling or thinking mode support
- Adding embedding/RAG capabilities
- Changing the remote server chat services (LM Studio, Ollama, etc.)

---

## Dependency Changes

### pubspec.yaml

**Remove:**
```yaml
flutter_litert_lm: ^0.3.0
```

**Add:**
```yaml
flutter_gemma: ^0.16.1
```

---

## Files to Delete

These files are entirely replaced by flutter_gemma's built-in APIs:

| File | Lines | Reason |
|------|-------|--------|
| `lib/features/on_device/data/on_device_engine_service.dart` | 132 | Replaced by `FlutterGemma.getActiveModel()` |
| `lib/features/on_device/data/model_downloader.dart` | 218 | Replaced by `FlutterGemma.installModel().fromNetwork()` |
| `lib/features/on_device/data/on_device_model_download_service.dart` | 101 | Replaced by FlutterGemma model management |
| `lib/features/on_device/data/foreground_download_service.dart` | 171 | Replaced by FlutterGemma progress callbacks |
| `lib/features/on_device/data/download_notification_service.dart` | ~100 | FlutterGemma handles Android foreground service |
| `lib/features/on_device/data/models/model_download_progress.dart` | ~50 | Replaced by int progress callback |

**Total removed: ~770 lines**

---

## Files to Create

### `lib/features/on_device/data/on_device_gemma_service.dart`

New engine service wrapping flutter_gemma. Responsibilities:
- Initialize FlutterGmma at app startup
- Install models from network with progress tracking
- Load/unload models with backend preference
- Create chat instances for inference
- Check installed models
- Delete models

**Key API surface:**

```dart
class OnDeviceGemmaService {
  // Initialization
  static Future<void> initialize({String? huggingFaceToken});

  // Model management
  Future<void> installModel(OnDeviceModel model, {void Function(int)? onProgress, String? token});
  Future<bool> isModelInstalled(String modelId);
  Future<List<String>> getInstalledModelIds();
  Future<void> deleteModel(String modelId);

  // Engine lifecycle
  Future<void> loadModel(String modelId, PreferredBackend backend, {int maxTokens = 2048});
  Future<void> unloadModel();
  bool get isLoaded;

  // Chat
  InferenceChat? createChat({String? systemInstruction});
  InferenceModel? get activeModel;
}
```

**Implementation notes:**
- `installModel` calls `FlutterGemma.installModel(modelType:, fileType: ModelFileType.litertlm).fromNetwork(url).withProgress(cb).install()`
- `loadModel` calls `FlutterGemma.getActiveModel(maxTokens:, preferredBackend:)`
- `createChat` calls `model.createChat(systemInstruction:)`
- `deleteModel` calls `FlutterGemma.uninstallModel(fileName)`
- `isModelInstalled` calls `FlutterGemma.isModelInstalled(fileName)`
- Model IDs map to filenames: `'$modelId.litertlm'`

---

## Files to Rewrite

### `lib/features/on_device/data/on_device_chat_service.dart`

**Current:** Wraps `LiteLmConversation`, streams `LiteLmMessage`
**New:** Creates `InferenceChat` from `OnDeviceGemmaService`, streams `ModelResponse`

**Key changes:**
- Remove all `flutter_litert_lm` imports
- Use `OnDeviceGemmaService` instead of `OnDeviceEngineService`
- For each `sendMessage()` call:
  1. Get or create `InferenceChat` from service
  2. Add conversation history as `Message.text()` chunks via `chat.addQueryChunk()`
  3. Call `chat.generateChatResponseAsync()` for streaming
  4. Map `TextResponse` → `ChatResponse(type: message, content: token)`
  5. Map `FunctionCallResponse` → `ChatResponse(type: toolCall, ...)`
  6. Map `ThinkingResponse` → `ChatResponse(type: reasoning, ...)`
- `cancelStream()` calls `chat.stopGeneration()` then `chat.close()`
- Store active chat reference for cancellation

**Message conversion:**
```dart
List<Message> _convertMessages(List<Message> messages) {
  return messages
    .where((m) => m.role == MessageRole.user || m.role == MessageRole.assistant || m.role == MessageRole.system)
    .map((m) => Message.text(text: m.content, isUser: m.role == MessageRole.user))
    .toList();
}
```

**Streaming mapping:**
```dart
Stream<ChatResponse> _mapGemmaStream(Stream<ModelResponse> stream) async* {
  await for (final response in stream) {
    if (response is TextResponse) {
      yield ChatResponse(type: ChatResponseType.message, content: response.token);
    } else if (response is FunctionCallResponse) {
      yield ChatResponse(type: ChatResponseType.toolCall,
        toolCall: ToolCallData(tool: response.name, arguments: response.args));
    } else if (response is ThinkingResponse) {
      yield ChatResponse(type: ChatResponseType.reasoning,
        reasoningContent: response.content);
    }
  }
  yield ChatResponse(type: ChatResponseType.done);
}
```

### `lib/features/on_device/providers/on_device_providers.dart`

**Key changes:**
- Replace `OnDeviceEngineService` references with `OnDeviceGemmaService`
- Replace `LiteLmBackendType` with `PreferredBackend` from flutter_gemma
- `OnDeviceEngineNotifier`:
  - `loadModel()` calls `gemmaService.loadModel(modelId, backend)`
  - Uses `ChatBackgroundService` for model loading (heavy mmap operation)
  - `unloadModel()` calls `gemmaService.unloadModel()`
- `OnDeviceModelStateNotifier`: no major changes
- Remove `modelDownloaderProvider`, `onDeviceDownloadServiceProvider`, `foregroundDownloadServiceProvider`
- Add `onDeviceGemmaServiceProvider` providing `OnDeviceGemmaService`
- Update `isOnDevicePlatformSupportedProvider` to support iOS

**Platform support provider:**
```dart
final isOnDevicePlatformSupportedProvider = Provider<bool>((ref) {
  return Platform.isAndroid || Platform.isIOS;
});
```

### `lib/features/on_device/providers/foreground_download_providers.dart`

**Rewrite to use flutter_gemma's download system:**
- `ForegroundDownloadNotifier.startDownload()` calls `OnDeviceGemmaService.installModel()` with progress callback
- Progress callback updates state directly (int 0-100)
- No more stream subscriptions or broadcast controllers
- Simplified pause/resume (flutter_gemma handles retry internally)
- Keep SharedPreferences persistence for download state across restarts

### `lib/features/on_device/views/model_manager_screen.dart`

**Key changes:**
- Remove `if (!isAndroid)` warning banner — all platforms supported
- Update download progress to use simplified flutter_gemma progress (int 0-100)
- Remove custom download UI complexity (pause/resume buttons — flutter_gemma handles retry)
- Keep memory health display
- Keep model cards with load/unload/delete actions

### `lib/features/on_device/data/models/on_device_model.dart`

**Add ModelType mapping:**
```dart
ModelType get flutterGemmaModelType {
  switch (id) {
    case 'qwen3-0.6b': return ModelType.qwen3;
    case 'qwen2.5-1.5b-instruct': return ModelType.qwen;
    case 'deepseek-r1-distill-qwen-1.5b': return ModelType.deepSeek;
    case 'gemma4-e2b-instruct': return ModelType.gemma4;
    default: return ModelType.general;
  }
}
```

**Update `fileName` getter:**
```dart
String get fileName => '$id.litertlm'; // unchanged — same format
```

### `lib/core/models/enums.dart`

**Changes:**
- Remove `LiteLmBackendType` enum (replaced by `PreferredBackend` from flutter_gemma)
- Keep `OnDeviceEngineStatus` and `OnDeviceModelState` enums
- Add import for `package:flutter_gemma/flutter_gemma.dart`

---

## Files to Update (Minor)

### `lib/features/chat/data/chat_service.dart`

Update `ChatService.forServer()` factory:
```dart
case ServerType.onDevice:
  if (onDeviceGemma == null) {
    throw StateError('OnDeviceGemmaService is required for onDevice server type');
  }
  return OnDeviceChatService(onDeviceGemma);
```

Change parameter from `OnDeviceEngineService? onDeviceEngine` to `OnDeviceGemmaService? onDeviceGemma`.

### `lib/features/chat/providers/chat_providers.dart`

Update `chatServiceProvider`:
```dart
final chatServiceProvider = Provider<ChatService?>((ref) {
  final server = ref.watch(activeServerProvider);
  if (server == null) return null;
  if (server.type == ServerType.onDevice) {
    final gemmaService = ref.read(onDeviceGemmaServiceProvider);
    return ChatService.forServer(server.type, ref.read(dioProvider), onDeviceGemma: gemmaService);
  }
  return ChatService.forServer(server.type, ref.read(dioProvider));
});
```

### `lib/core/services/chat_background_service.dart`

**Simplify:** Still needed for model loading (heavy mmap), but download foreground service is handled by flutter_gemma. Keep start/stop for model load operations.

### `android/app/src/main/AndroidManifest.xml`

Add GPU support if not already present:
```xml
<uses-native-library android:name="libOpenCL.so" android:required="false"/>
<uses-native-library android:name="libOpenCL-car.so" android:required="false"/>
<uses-native-library android:name="libOpenCL-pixel.so" android:required="false"/>
```

### `ios/Podfile`

```ruby
platform :ios, '16.0'
use_frameworks! :linkage => :static
```

### `ios/Runner/Info.plist`

Add:
```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>NSLocalNetworkUsageDescription</key>
<string>This app requires local network access for model inference services.</string>
```

### `ios/Runner/Runner.entitlements`

Add memory entitlements:
```xml
<key>com.apple.developer.kernel.extended-virtual-addressing</key>
<true/>
<key>com.apple.developer.kernel.increased-memory-limit</key>
<true/>
```

---

## Model Storage Consideration

flutter_gemma manages its own model storage. Existing models downloaded by the custom `ModelDownloader` to `{appSupportDir}/on_device_models/{modelId}.litertlm` will NOT be automatically recognized by flutter_gemma.

**Migration approach:**
1. On first launch after migration, check for existing `.litertlm` files in the old location
2. For each found model, use `FlutterGemma.installModel().fromFile(oldPath).install()` to register it
3. This avoids re-downloading multi-GB models
4. Old directory can be cleaned up after successful registration

---

## Initialization

Add to `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize flutter_gemma
  await OnDeviceGemmaService.initialize(
    huggingFaceToken: const String.fromEnvironment('HUGGINGFACE_TOKEN'),
  );
  
  runApp(MyApp());
}
```

---

## Testing Strategy

1. **Unit tests:** Mock `FlutterGemmaPlugin` for `OnDeviceGemmaService` tests
2. **Widget tests:** Model manager screen with mocked providers
3. **Integration tests:** Full download → load → inference flow on each platform
4. **Platform matrix:** Android (arm64), iOS (arm64)

---

## Platform Setup Checklist

### Android
- [x] Already supported
- [ ] Add OpenCL manifest entries for GPU support

### iOS (NEW)
- [ ] Set minimum iOS 16.0 in Podfile
- [ ] Enable file sharing in Info.plist
- [ ] Add memory entitlements in Runner.entitlements
- [ ] Set static linkage in Podfile
- [ ] Add network usage description
