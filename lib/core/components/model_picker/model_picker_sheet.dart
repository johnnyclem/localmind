import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/providers/model_loading_providers.dart';
import 'package:localmind/core/providers/on_device_providers.dart';
import 'package:localmind/core/providers/model_selection_providers.dart';
import 'package:localmind/core/providers/server_providers.dart';
import 'package:localmind/core/theme/colors.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'model_list.dart';
import 'model_picker_header.dart';
import 'model_search_field.dart';
import 'no_server_state.dart';
import 'on_device_picker_section.dart';

class ModelPickerSheet extends ConsumerWidget {
  const ModelPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeServer = ref.watch(activeServerProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final modelLoading = ref.watch(modelLoadingProvider);
    final isThinking = ref.watch(modelThinkingProvider);

    ref.listen(onDeviceEngineProvider, (prev, next) {
      if (next.status == OnDeviceEngineStatus.loaded &&
          prev?.status == OnDeviceEngineStatus.loading) {
        final loadedId = next.loadedModelId;
        final models = ref.read(onDeviceModelsProvider);
        final loadedName = loadedId == null
            ? 'Unknown'
            : models
                  .where((m) => m.id == loadedId)
                  .map((m) => m.name)
                  .followedBy([loadedId])
                  .first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.model_loaded(
                loadedName,
                next.backend?.name ?? 'CPU',
              ),
            ),
          ),
        );
      }
    });

    final serversAsync = ref.watch(serversProvider);
    final servers = serversAsync.value ?? [];
    final currentServer =
        servers.where((s) => s.id == activeServer?.id).firstOrNull;
    final isOnDevice =
        currentServer != null && currentServer.type == ServerType.onDevice;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ModelPickerHeader(
            isDark: isDark,
            isThinking: isThinking,
            modelLoading: modelLoading,
            onRefresh: activeServer != null
                ? () {
                    ref.invalidate(availableModelsProvider(activeServer.id));
                    ref.invalidate(loadedModelsProvider(activeServer));
                  }
                : null,
          ),
          if (activeServer != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                activeServer.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const ModelSearchField(),
          const SizedBox(height: 12),
          Expanded(
            child: activeServer == null
                ? NoServerState(isDark: isDark)
                : isOnDevice
                    ? OnDevicePickerSection(
                        selectedModelId: selectedModel?.id,
                        isDark: isDark,
                      )
                    : ModelList(
                        serverId: activeServer.id,
                        selectedModelId: selectedModel?.id,
                        isDark: isDark,
                      ),
          ),
        ],
      ),
    );
  }
}
