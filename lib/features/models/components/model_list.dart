import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/features/chat/providers/model_loading_providers.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/providers/app_providers.dart';
import 'package:localmind/core/providers/service_providers.dart';
import 'package:localmind/core/theme/colors.dart';
import 'package:localmind/features/chat/providers/model_selection_providers.dart';
import 'package:localmind/features/models/data/models/model_info.dart';
import 'package:localmind/features/models/providers/model_picker_providers.dart';
import 'package:localmind/features/servers/providers/server_providers.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'model_tile.dart';

class ModelList extends ConsumerWidget {
  const ModelList({
    super.key,
    required this.serverId,
    required this.selectedModelId,
    required this.isDark,
  });

  final String serverId;
  final String? selectedModelId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(modelSearchQueryProvider);
    final modelsAsync = ref.watch(availableModelsProvider(serverId));

    return modelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              l10n.failed_load_models,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              err.toString(),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(availableModelsProvider(serverId)),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (models) {
        final serversAsync = ref.watch(serversProvider);
        final servers = serversAsync.value ?? [];
        final activeServer = servers.where((s) => s.id == serverId).firstOrNull;
        final loadedModelsAsync = activeServer != null
            ? ref.watch(loadedModelsProvider(activeServer))
            : const AsyncValue<Set<String>>.data(<String>{});

        final loadedModels = loadedModelsAsync.maybeWhen(
          data: (data) => data,
          orElse: () => <String>{},
        );

        final modelList = models.cast<ModelInfo>();
        final filtered = searchQuery.isEmpty
            ? modelList
            : modelList
                  .where(
                    (m) =>
                        m.displayName.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        m.id.toLowerCase().contains(searchQuery.toLowerCase()),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isEmpty
                  ? l10n.no_models_available
                  : l10n.no_models_match(searchQuery),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final model = filtered[index];
            final isSelected = model.id == selectedModelId;
            final isLoaded = loadedModels.contains(model.id);

            return ModelTile(
              model: model,
              isSelected: isSelected,
              isLoaded: isLoaded,
              isDark: isDark,
              onTap: () async {
                final activeServer = ref.read(activeServerProvider);
                if (activeServer == null) return;

                final supportsLoad = model.serverType == ServerType.lmStudio;

                if (supportsLoad && !isLoaded) {
                  ref.read(modelLoadingProvider.notifier).setLoading(model.id);

                  try {
                    final apiService = ref.read(serverApiServiceProvider);
                    await apiService.loadModelWithInstanceId(
                      activeServer,
                      model.id,
                    );

                    ref.invalidate(loadedModelsProvider(activeServer));
                    ref.read(modelLoadingProvider.notifier).setLoaded();
                  } catch (e) {
                    ref.read(modelLoadingProvider.notifier).setLoaded();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.model_load_failed(e.toString())),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                }

                ref.read(selectedModelProvider.notifier).setModel(model);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              onUnload: () async {
                final activeServer = ref.read(activeServerProvider);
                if (activeServer == null) return;

                try {
                  final apiService = ref.read(serverApiServiceProvider);
                  await apiService.unloadModel(activeServer, model.id);
                  ref.invalidate(loadedModelsProvider(activeServer));

                  final selectedModel = ref.read(selectedModelProvider);
                  if (selectedModel?.id == model.id) {
                    ref.read(selectedModelProvider.notifier).clear();
                  }

                  if (context.mounted) {
                    final message = activeServer.type == ServerType.ollama
                        ? l10n.model_unloaded_ollama(model.name)
                        : l10n.model_unloaded_success(model.name);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.model_unload_failed(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}
