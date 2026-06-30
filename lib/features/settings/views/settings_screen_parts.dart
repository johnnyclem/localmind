part of 'settings_screen.dart';

List<Widget> _withVerticalSpacing(List<Widget> children, {double gap = 12}) {
  if (children.isEmpty) {
    return const [];
  }

  return [
    for (var index = 0; index < children.length; index++) ...[
      children[index],
      if (index != children.length - 1) SizedBox(height: gap),
    ],
  ];
}

Color _panelColor(BuildContext context) {
  final scheme = ShadTheme.of(context).colorScheme;
  return scheme.secondary;
}

Color _surfaceColor(BuildContext context) {
  return ShadTheme.of(context).colorScheme.card;
}

Color _primaryColor(BuildContext context) {
  return ShadTheme.of(context).colorScheme.primary;
}

Color _outlineColor(BuildContext context, {double alpha = 0.6}) {
  return ShadTheme.of(context).colorScheme.border.withValues(alpha: alpha);
}

Color _mutedColor(BuildContext context) {
  return ShadTheme.of(context).colorScheme.mutedForeground;
}

String _themeLabel(AppThemeType themeType, AppLocalizations l10n) {
  return switch (themeType) {
    AppThemeType.system => l10n.theme_system,
    AppThemeType.light => l10n.theme_light,
    AppThemeType.dark => l10n.theme_dark,
    AppThemeType.claude => l10n.theme_claude,
  };
}

String _engineLabel(EngineId engine, AppLocalizations l10n) {
  return switch (engine) {
    EngineId.system => l10n.tts_engine_system,
    EngineId.kitten => l10n.tts_engine_kitten,
    EngineId.piper => EngineMeta.piper.name,
  };
}

String _languageLabel(String? localeCode, AppLocalizations l10n) {
  if (localeCode == null) {
    return l10n.language_system_default;
  }

  for (final item in _LanguageSetting.localeItems) {
    if (item.$1 == localeCode) {
      return item.$2;
    }
  }

  return localeCode.toUpperCase();
}
