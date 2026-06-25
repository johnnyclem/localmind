import 'package:flutter/material.dart';
import 'package:localmind/core/theme/colors.dart';

class MetadataChip extends StatelessWidget {
  const MetadataChip({super.key, required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
        ),
      ),
    );
  }
}
