import 'package:flutter/material.dart';
import 'package:localmind/core/theme/colors.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'thinking_indicator.dart';

class ModelPickerHeader extends StatelessWidget {
  const ModelPickerHeader({
    super.key,
    required this.isDark,
    required this.isThinking,
    required this.modelLoading,
    this.onRefresh,
  });

  final bool isDark;
  final bool isThinking;
  final dynamic modelLoading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.select_model_title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (isThinking) ...[
                    const SizedBox(width: 8),
                    ThinkingIndicator(isDark: isDark),
                  ],
                ],
              ),
              if (modelLoading.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ModelLoadingBar(
                    isDark: isDark,
                    modelId: modelLoading.modelId,
                    progress: modelLoading.progress,
                  ),
                ),
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: onRefresh,
            tooltip: l10n.refresh_models,
          ),
      ],
    );
  }
}

class ModelLoadingBar extends StatelessWidget {
  const ModelLoadingBar({
    super.key,
    required this.isDark,
    required this.modelId,
    this.progress,
  });

  final bool isDark;
  final String? modelId;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.loading_model(modelId ?? 'model'),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor:
              isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ],
    );
  }
}
