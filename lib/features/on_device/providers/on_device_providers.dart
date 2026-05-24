import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/chat_background_service_provider.dart';
import '../data/models/on_device_model.dart';
import '../data/notification_permission_service.dart';
import '../data/on_device_gemma_service.dart';

final notificationPermissionServiceProvider =
    Provider<NotificationPermissionService>((ref) {
  return NotificationPermissionService();
});

final onDeviceGemmaServiceProvider = Provider<OnDeviceGemmaService>((ref) {
  final service = OnDeviceGemmaService();
  ref.onDispose(() => service.dispose());
  return service;
});

final onDeviceEngineProvider =
    NotifierProvider<OnDeviceEngineNotifier, OnDeviceEngineState>(() {
      return OnDeviceEngineNotifier();
    });

final onDeviceModelsProvider = Provider<List<OnDeviceModel>>((ref) {
  return OnDeviceModel.curatedModels;
});

final downloadedModelsProvider = FutureProvider<Set<String>>((ref) async {
  final gemmaService = ref.read(onDeviceGemmaServiceProvider);
  final installed = await gemmaService.getInstalledModelIds();
  return installed.toSet();
});

final onDeviceModelStateProvider =
    NotifierProvider<
      OnDeviceModelStateNotifier,
      Map<String, OnDeviceModelStateInfo>
    >(() {
      return OnDeviceModelStateNotifier();
    });

class OnDeviceEngineState {
  final OnDeviceEngineStatus status;
  final String? loadedModelId;
  final PreferredBackend? backend;
  final String? error;

  const OnDeviceEngineState({
    this.status = OnDeviceEngineStatus.notLoaded,
    this.loadedModelId,
    this.backend,
    this.error,
  });

  OnDeviceEngineState copyWith({
    OnDeviceEngineStatus? status,
    String? loadedModelId,
    PreferredBackend? backend,
    String? error,
  }) {
    return OnDeviceEngineState(
      status: status ?? this.status,
      loadedModelId: loadedModelId ?? this.loadedModelId,
      backend: backend ?? this.backend,
      error: error ?? this.error,
    );
  }
}

class OnDeviceEngineNotifier extends Notifier<OnDeviceEngineState> {
  @override
  OnDeviceEngineState build() {
    return const OnDeviceEngineState();
  }

  OnDeviceGemmaService get _gemmaService =>
      ref.read(onDeviceGemmaServiceProvider);

  Future<void> loadModel(String modelId, PreferredBackend backend) async {
    state = state.copyWith(status: OnDeviceEngineStatus.loading, error: null);

    // Protect the heavy native model-load from Android CPU throttling
    final bgService = ref.read(chatBackgroundServiceProvider);
    await bgService.start();

    try {
      final isInstalled = await _gemmaService.isModelInstalled(modelId);
      if (!isInstalled) {
        state = state.copyWith(
          status: OnDeviceEngineStatus.error,
          error: 'Model not found. Please download it first.',
        );
        return;
      }

      await _gemmaService.loadModel(modelId, backend);

      state = state.copyWith(
        status: OnDeviceEngineStatus.loaded,
        loadedModelId: modelId,
        backend: backend,
      );

      Log.info('Model $modelId loaded successfully with ${backend.name}');
    } catch (e) {
      Log.error('Failed to load model $modelId: $e');
      state = state.copyWith(
        status: OnDeviceEngineStatus.error,
        error: 'Failed to load model: ${e.toString()}',
      );
    } finally {
      await bgService.stop();
    }
  }

  Future<void> unloadModel() async {
    try {
      await _gemmaService.unloadModel();
    } catch (_) {}
    state = const OnDeviceEngineState();
  }

  Future<void> disposeService() async {
    _gemmaService.dispose();
    state = const OnDeviceEngineState();
  }
}

class OnDeviceModelStateNotifier
    extends Notifier<Map<String, OnDeviceModelStateInfo>> {
  @override
  Map<String, OnDeviceModelStateInfo> build() {
    return {};
  }

  void updateModelState(
    String modelId, {
    OnDeviceModelState? modelState,
    double? downloadProgress,
    String? error,
    PreferredBackend? backend,
    OnDeviceEngineStatus? engineStatus,
  }) {
    final current =
        state[modelId] ?? OnDeviceModelStateInfo(modelId: modelId);
    state = {
      ...state,
      modelId: current.copyWith(
        state: modelState ?? current.state,
        downloadProgress: downloadProgress ?? current.downloadProgress,
        error: error ?? current.error,
        backend: backend ?? current.backend,
        engineStatus: engineStatus ?? current.engineStatus,
      ),
    };
  }

  void setDownloading(String modelId, double progress) {
    updateModelState(
      modelId,
      modelState: OnDeviceModelState.downloading,
      downloadProgress: progress,
    );
  }

  void setDownloaded(String modelId) {
    updateModelState(
      modelId,
      modelState: OnDeviceModelState.downloaded,
      downloadProgress: 1.0,
    );
  }

  void setDownloadError(String modelId, String error) {
    updateModelState(
      modelId,
      modelState: OnDeviceModelState.error,
      error: error,
    );
  }

  void removeModel(String modelId) {
    final newState = Map<String, OnDeviceModelStateInfo>.from(state);
    newState.remove(modelId);
    state = newState;
  }
}

final isOnDevicePlatformSupportedProvider = Provider<bool>((ref) {
  return Platform.isAndroid || Platform.isIOS;
});
