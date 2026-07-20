import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hypervault/providers/hypervault_providers.dart';
import '../data/hypervault_backends_service.dart';
import '../data/models/hv_backend.dart';

final hyperVaultBackendsServiceProvider = Provider<HyperVaultBackendsService>((
  ref,
) {
  return HyperVaultBackendsService(ref.read(hyperVaultApiClientProvider));
});

final hyperVaultBackendsProvider =
    AsyncNotifierProvider<HyperVaultBackendsNotifier, HvBackendsSnapshot>(
      HyperVaultBackendsNotifier.new,
    );

class HyperVaultBackendsNotifier extends AsyncNotifier<HvBackendsSnapshot> {
  @override
  Future<HvBackendsSnapshot> build() async {
    final session = ref.watch(hyperVaultSessionProvider);
    if (session == null) return const HvBackendsSnapshot();
    return ref.read(hyperVaultBackendsServiceProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(hyperVaultBackendsServiceProvider).list(),
    );
  }

  /// Throws [HvApiError] on failure — the caller surfaces the server's
  /// `{error}` verbatim rather than this notifier swallowing it.
  Future<HvBackendMutationResult> addBackend({
    required String provider,
    String? name,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    String? embeddingModel,
  }) async {
    final result = await ref
        .read(hyperVaultBackendsServiceProvider)
        .create(
          provider: provider,
          name: name,
          apiKey: apiKey,
          baseUrl: baseUrl,
          defaultModel: defaultModel,
          embeddingModel: embeddingModel,
        );
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        HvBackendsSnapshot(
          backends: [result.backend, ...current.backends],
          providers: current.providers,
        ),
      );
    }
    return result;
  }

  Future<HvBackendMutationResult> editBackend({
    required String id,
    required String name,
    required String baseUrl,
    required String defaultModel,
    String? embeddingModel,
    String? apiKey,
  }) async {
    final result = await ref
        .read(hyperVaultBackendsServiceProvider)
        .update(
          id: id,
          name: name,
          baseUrl: baseUrl,
          defaultModel: defaultModel,
          embeddingModel: embeddingModel,
          apiKey: apiKey,
        );
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        HvBackendsSnapshot(
          backends: [
            for (final backend in current.backends)
              if (backend.id == id) result.backend else backend,
          ],
          providers: current.providers,
        ),
      );
    }
    return result;
  }

  Future<String> removeBackend(String id) async {
    final message = await ref
        .read(hyperVaultBackendsServiceProvider)
        .delete(id);
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        HvBackendsSnapshot(
          backends: current.backends.where((b) => b.id != id).toList(),
          providers: current.providers,
        ),
      );
    }
    return message;
  }
}
