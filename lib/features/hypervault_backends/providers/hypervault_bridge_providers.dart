import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/service_providers.dart';
import '../../chat/providers/chat_service_providers.dart'
    show createChatServiceForServer;
import '../../on_device/data/on_device_chat_service.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../../servers/data/models/server.dart';
import '../../hypervault/data/models/hv_api_error.dart';
import '../../hypervault/providers/hypervault_providers.dart';
import '../data/hypervault_on_device_bridge.dart';

final hyperVaultOnDeviceBridgeServiceProvider =
    Provider<HyperVaultOnDeviceBridgeService>((ref) {
      return HyperVaultOnDeviceBridgeService(
        ref.read(hyperVaultApiClientProvider),
      );
    });

final hyperVaultBridgeRunProvider =
    NotifierProvider<HyperVaultBridgeRunNotifier, HvBridgeRunState>(
      HyperVaultBridgeRunNotifier.new,
    );

class HvBridgeRunState {
  final bool running;
  final String? error;
  final HvBridgeRoundTripResult? result;

  const HvBridgeRunState({this.running = false, this.error, this.result});
}

/// Orchestrates one context→on-device-generate→turns round trip for the
/// standalone bridge screen. Reuses LocalMind's existing on-device
/// `ChatService` implementations (gemma/llama.cpp, whichever is currently
/// loaded via [onDeviceEngineProvider]) rather than reimplementing
/// inference; this is a power-user toggle exercised from its own screen, not
/// a change to the default chat flow.
class HyperVaultBridgeRunNotifier extends Notifier<HvBridgeRunState> {
  @override
  HvBridgeRunState build() => const HvBridgeRunState();

  Future<void> run({
    required String message,
    bool useRecall = true,
    bool? useSmartContext,
    bool? useDeepMemory,
  }) async {
    final engine = ref.read(onDeviceEngineProvider);
    final modelId = engine.loadedModelId;
    if (engine.status != OnDeviceEngineStatus.loaded || modelId == null) {
      state = const HvBridgeRunState(
        error:
            'Load an on-device model first (On-device Models), then run this again.',
      );
      return;
    }

    state = const HvBridgeRunState(running: true);

    final onDeviceServer = Server(
      id: 'hypervault-on-device-bridge',
      name: 'On-device',
      type: ServerType.onDevice,
      host: '',
      port: 0,
      createdAt: DateTime.now(),
      lastConnectedAt: DateTime.now(),
    );
    final chatService = createChatServiceForServer(
      server: onDeviceServer,
      dio: ref.read(dioProvider),
      onDeviceGemmaService: ref.read(onDeviceGemmaServiceProvider),
      onDeviceLlamaService: ref.read(onDeviceLlamaServiceProvider),
      loadedOnDeviceRuntime: engine.loadedRuntime,
    );

    try {
      final result = await ref
          .read(hyperVaultOnDeviceBridgeServiceProvider)
          .runRoundTrip(
            message: message,
            onDeviceModelId: modelId,
            useRecall: useRecall,
            useSmartContext: useSmartContext,
            useDeepMemory: useDeepMemory,
            generate:
                ({required modelId, required messages, required params}) =>
                    chatService.sendMessage(
                      server: onDeviceServer,
                      modelId: modelId,
                      messages: messages,
                      params: params,
                    ),
          );
      state = HvBridgeRunState(result: result);
    } on HvApiError catch (e) {
      state = HvBridgeRunState(error: e.error);
    } catch (e) {
      state = HvBridgeRunState(error: e.toString());
    } finally {
      if (chatService is OnDeviceChatService) {
        chatService.dispose();
      }
    }
  }

  void reset() => state = const HvBridgeRunState();
}
