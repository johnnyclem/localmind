import 'package:flutter/material.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/theme/colors.dart';
import 'package:localmind/features/models/data/models/model_info.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'metadata_chip.dart';

class ModelTile extends StatelessWidget {
  const ModelTile({
    super.key,
    required this.model,
    required this.isSelected,
    required this.isLoaded,
    required this.isDark,
    required this.onTap,
    this.onUnload,
  });

  final ModelInfo model;
  final bool isSelected;
  final bool isLoaded;
  final bool isDark;
  final VoidCallback onTap;
  final Future<void> Function()? onUnload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: accent.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          model.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (model.parameterCountDisplay != null &&
                          model.parameterCountDisplay!.isNotEmpty)
                        MetadataChip(
                          label: model.parameterCountDisplay!,
                          isDark: isDark,
                        ),
                      if (model.quantization != null &&
                          model.quantization!.isNotEmpty)
                        MetadataChip(
                          label: model.quantization!,
                          isDark: isDark,
                        ),
                      if (model.formattedSize != null &&
                          model.formattedSize!.isNotEmpty)
                        MetadataChip(
                          label: model.formattedSize!,
                          isDark: isDark,
                        ),
                      if (model.contextLength != null)
                        MetadataChip(
                          label: l10n.context_chip(
                            model.contextLength.toString(),
                          ),
                          isDark: isDark,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (model.serverType == ServerType.lmStudio ||
                model.serverType == ServerType.ollama) ...[
              if (isLoaded) ...[
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              if (isLoaded) ...[
                IconButton(
                  icon: Icon(
                    Icons.power_settings_new_outlined,
                    size: 18,
                    color: Colors.red[400],
                  ),
                  onPressed: onUnload,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: l10n.unload_from_server,
                ),
                const SizedBox(width: 8),
              ],
            ],
            if (isSelected)
              Icon(Icons.check_circle, color: accent, size: 22)
            else
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
          ],
        ),
      ),
    );
  }
}
