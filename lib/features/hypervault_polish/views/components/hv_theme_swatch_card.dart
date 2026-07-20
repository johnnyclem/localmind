import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/hv_theme_pair.dart';

/// One swatch card for a [HvThemePair], rendered inside its own [Theme] +
/// [ShadTheme] scope so the card actually shows the mapped theme's colors
/// rather than the app's ambient theme.
class HvThemeSwatchCard extends StatelessWidget {
  final HvThemePair pair;

  const HvThemeSwatchCard({super.key, required this.pair});

  @override
  Widget build(BuildContext context) {
    final palette = pair.themeData.colorScheme;
    return Theme(
      data: pair.themeData,
      child: ShadTheme(
        data: pair.shadThemeData,
        child: Semantics(
          label:
              '${pair.source.name} theme, ${pair.isDark ? "dark" : "light"} mode',
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              color: pair.themeData.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.outline),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pair.source.name,
                        style: pair.themeData.textTheme.titleSmall?.copyWith(
                          color: palette.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    HugeIcon(
                      icon: pair.isDark
                          ? HugeIcons.strokeRoundedMoon02
                          : HugeIcons.strokeRoundedSun03,
                      color: palette.onSurface.withValues(alpha: 0.6),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _dot(palette.primary),
                    const SizedBox(width: 6),
                    _dot(palette.surface, border: palette.outline),
                    const SizedBox(width: 6),
                    _dot(palette.error),
                  ],
                ),
                const SizedBox(height: 10),
                ShadButton(
                  onPressed: () {},
                  child: const Text('Preview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, {Color? border}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border != null ? Border.all(color: border) : null,
      ),
    );
  }
}
