import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_capabilities.dart';
import 'models/hv_theme_pair.dart';

/// Maps a `capabilities.themes` catalog entry (`{id, name, mode}`) to a
/// [HvThemePair], following the same [ThemeData]/[ShadThemeData] shape as
/// `AppTheme` (lib/core/theme/app_theme.dart).
///
/// The capabilities payload only ever describes a theme by id/name/mode —
/// HyperVault's actual CSS custom-property palette for each of its ~30
/// designprompts.dev-derived styles lives in the web app's `globals.css` and
/// isn't part of the mobile API contract. Rather than hard-coding a second,
/// inevitably-drifting copy of ~30 palettes here, each theme's accent hue is
/// derived deterministically from its `id` (stable across app runs and
/// rebuilds of the catalog) and combined with light/dark tokens shaped like
/// [AppColors]. This gives every catalog entry a distinct, reproducible look
/// for the preview gallery without guessing at colors HyperVault hasn't
/// published to mobile. A follow-up that wants pixel parity with the web
/// swatches would extend `GET /api/capabilities` to include each theme's
/// resolved CSS variables and swap the derivation below for a direct read.
class HvThemeMapper {
  const HvThemeMapper._();

  static HvThemePair pairFor(HvTheme theme) {
    final hue = _hueFor(theme.id.isEmpty ? theme.name : theme.id);
    final isDark = theme.mode != 'light';
    final palette = _HvPalette.derive(hue: hue, isDark: isDark);
    return HvThemePair(
      source: theme,
      themeData: _buildThemeData(palette),
      shadThemeData: _buildShadThemeData(palette),
    );
  }

  static List<HvThemePair> allFor(Iterable<HvTheme> themes) =>
      themes.map(pairFor).toList(growable: false);
}

/// Deterministic hue in [0, 360) from a theme id — same algorithm every run,
/// so a given theme id always renders the same swatch.
double _hueFor(String seed) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return (hash % 360).toDouble();
}

Color _hsl(double hue, double saturation, double lightness) =>
    HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();

class _HvPalette {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceInput;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color primaryText;
  final Color mutedText;
  final Color error;

  const _HvPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceInput,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.mutedText,
    required this.error,
  });

  factory _HvPalette.derive({required double hue, required bool isDark}) {
    if (isDark) {
      return _HvPalette(
        brightness: Brightness.dark,
        background: _hsl(hue, 0.18, 0.10),
        surface: _hsl(hue, 0.16, 0.14),
        surfaceInput: _hsl(hue, 0.16, 0.18),
        border: _hsl(hue, 0.16, 0.27),
        primary: _hsl(hue, 0.68, 0.64),
        onPrimary: _hsl(hue, 0.18, 0.10),
        primaryText: _hsl(hue, 0.08, 0.93),
        mutedText: _hsl(hue, 0.10, 0.68),
        error: const Color(0xFFEF4444),
      );
    }
    return _HvPalette(
      brightness: Brightness.light,
      background: _hsl(hue, 0.30, 0.97),
      surface: _hsl(hue, 0.22, 0.995),
      surfaceInput: _hsl(hue, 0.22, 0.97),
      border: _hsl(hue, 0.20, 0.88),
      primary: _hsl(hue, 0.55, 0.45),
      onPrimary: Colors.white,
      primaryText: _hsl(hue, 0.18, 0.13),
      mutedText: _hsl(hue, 0.12, 0.42),
      error: const Color(0xFFDC2626),
    );
  }
}

ThemeData _buildThemeData(_HvPalette p) {
  final isDark = p.brightness == Brightness.dark;
  final colorScheme = isDark
      ? ColorScheme.dark(
          surface: p.surface,
          primary: p.primary,
          onPrimary: p.onPrimary,
          secondary: p.primary,
          onSecondary: p.onPrimary,
          error: p.error,
          onSurface: p.primaryText,
          outline: p.border,
        )
      : ColorScheme.light(
          surface: p.surface,
          primary: p.primary,
          onPrimary: p.onPrimary,
          secondary: p.primary,
          onSecondary: p.onPrimary,
          error: p.error,
          onSurface: p.primaryText,
          outline: p.border,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    scaffoldBackgroundColor: p.background,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.primaryText,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: p.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surface,
      contentTextStyle: TextStyle(color: p.primaryText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.background,
      indicatorColor: p.surface,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? p.primaryText : p.mutedText,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? p.primaryText
              : p.mutedText,
        );
      }),
    ),
  );
}

ShadThemeData _buildShadThemeData(_HvPalette p) {
  final isDark = p.brightness == Brightness.dark;
  return ShadThemeData(
    brightness: p.brightness,
    colorScheme: isDark
        ? ShadSlateColorScheme.dark(
            background: p.background,
            primary: p.primary,
            primaryForeground: p.onPrimary,
            secondary: p.surface,
            secondaryForeground: p.primaryText,
            border: p.border,
            card: p.surface,
            cardForeground: p.primaryText,
            muted: p.surface,
            mutedForeground: p.mutedText,
          )
        : ShadSlateColorScheme.light(
            background: p.background,
            primary: p.primary,
            primaryForeground: p.onPrimary,
            secondary: p.surface,
            secondaryForeground: p.primaryText,
            border: p.border,
            card: p.surface,
            cardForeground: p.primaryText,
            muted: p.surface,
            mutedForeground: p.mutedText,
          ),
  );
}
