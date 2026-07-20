import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_capabilities.dart';

/// A [ThemeData]/[ShadThemeData] pair derived from one
/// `capabilities.themes` catalog entry, mirroring the shape of
/// `AppTheme.lightTheme`/`AppTheme.darkTheme`/`AppTheme.claudeTheme` +
/// their matching `*ShadTheme` getters (lib/core/theme/app_theme.dart) so a
/// follow-up can drop these into [ThemeModeNotifier] the same way.
class HvThemePair {
  final HvTheme source;
  final ThemeData themeData;
  final ShadThemeData shadThemeData;

  const HvThemePair({
    required this.source,
    required this.themeData,
    required this.shadThemeData,
  });

  bool get isDark => source.mode == 'dark';
}
