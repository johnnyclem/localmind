part of 'settings_screen.dart';

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.settings, required this.themeType});

  final AppSettings settings;
  final AppThemeType themeType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primary = _primaryColor(context);

    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _outlineColor(context, alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.settings_title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.app_tagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _mutedColor(context),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroStat(
                  label: l10n.theme,
                  value: _themeLabel(themeType, l10n),
                  icon: Icons.auto_awesome_rounded,
                ),
                _HeroStat(
                  label: l10n.settings_language,
                  value: _languageLabel(settings.localeCode, l10n),
                  icon: Icons.language_rounded,
                ),
                _HeroStat(
                  label: l10n.tts_engine,
                  value: _engineLabel(settings.ttsEngine, l10n),
                  icon: Icons.record_voice_over_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = _primaryColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _panelColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outlineColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: _mutedColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outlineColor(context, alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._withVerticalSpacing(children, gap: 10),
          ],
        ),
      ),
    );
  }
}

class _SettingPanel extends StatelessWidget {
  const _SettingPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panelColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _outlineColor(context)),
      ),
      child: child,
    );
  }
}

class _MutedCallout extends StatelessWidget {
  const _MutedCallout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _SettingPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_moon_outlined,
            size: 18,
            color: _mutedColor(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _mutedColor(context),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({
    required this.title,
    required this.subtitle,
    required this.providers,
    required this.highlights,
    required this.stack,
    required this.openSource,
  });

  final String title;
  final String subtitle;
  final List<String> providers;
  final List<String> highlights;
  final List<String> stack;
  final String openSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _mutedColor(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _AboutLabel(label: l10n.app_tagline),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: providers
                .map(
                  (provider) =>
                      _AboutChip(label: provider, icon: Icons.hub_outlined),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          _AboutLabel(label: l10n.highlights_label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: highlights
                .map(
                  (highlight) => _AboutChip(
                    label: highlight,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          _AboutLabel(label: l10n.built_with_label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: stack
                .map(
                  (item) => _AboutChip(label: item, icon: Icons.code_rounded),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surfaceColor(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _outlineColor(context, alpha: 0.8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: _mutedColor(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    openSource,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _mutedColor(context),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutLabel extends StatelessWidget {
  const _AboutLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: _mutedColor(context),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AboutChip extends StatelessWidget {
  const _AboutChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _outlineColor(context, alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _mutedColor(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting({required this.current, required this.onChanged});

  static const localeItems = <(String, String, String, String)>[
    ('en', 'English', 'assets/images/flag_us.png', '🇺🇸'),
    ('ja', '日本語', 'assets/images/flag_jp.png', '🇯🇵'),
    ('it', 'Italiano', 'assets/images/flag_it.png', '🇮🇹'),
    ('es', 'Español', 'assets/images/flag_es.png', '🇪🇸'),
    ('zh', '简体中文', 'assets/images/flag_cn.png', '🇨🇳'),
    ('zh_TW', '繁體中文', 'assets/images/flag_tw.png', '🇹🇼'),
    ('ar', 'العربية', 'assets/images/flag_sa.png', '🇸🇦'),
    ('bn', 'বাংলা', 'assets/images/flag_bd.png', '🇧🇩'),
    ('hi', 'हिन्दी', 'assets/images/flag_in.png', '🇮🇳'),
  ];

  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingHeader(label: l10n.settings_language),
          const SizedBox(height: 10),
          _InputShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: current,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: theme.colorScheme.surface,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_suggest_outlined,
                          size: 18,
                          color: _mutedColor(context),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            l10n.language_system_default,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...localeItems.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.$1,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _outlineColor(context, alpha: 0.8),
                                width: 0.6,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                item.$3,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      item.$4,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              item.$2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.description,
    required this.onChanged,
    this.valueFormat,
    this.previewText,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String description;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormat;
  final String? previewText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final displayValue = valueFormat != null
        ? valueFormat!(value)
        : value.toStringAsFixed(2);

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  displayValue,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: primary,
              thumbColor: primary,
              overlayColor: primary.withValues(alpha: 0.12),
              inactiveTrackColor: _outlineColor(context, alpha: 0.6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _mutedColor(context),
              height: 1.4,
            ),
          ),
          if (previewText != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _outlineColor(context, alpha: 0.75)),
              ),
              child: Text(
                previewText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: value.clamp(12.0, 24.0),
                  color: _mutedColor(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  const _ToggleSetting({
    required this.label,
    required this.value,
    required this.onChanged,
    this.badges = const [],
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<Widget> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SettingPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ...badges,
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.22)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFFB45309),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(themeModeProvider);

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingHeader(label: l10n.theme),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 8.0;
              final columns = constraints.maxWidth >= 700
                  ? 4
                  : constraints.maxWidth >= 420
                  ? 2
                  : 1;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _ThemeOption(
                      label: l10n.theme_system,
                      icon: Icons.brightness_auto_rounded,
                      isSelected: currentTheme == AppThemeType.system,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(AppThemeType.system),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ThemeOption(
                      label: l10n.theme_light,
                      icon: Icons.light_mode_rounded,
                      isSelected: currentTheme == AppThemeType.light,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(AppThemeType.light),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ThemeOption(
                      label: l10n.theme_dark,
                      icon: Icons.dark_mode_rounded,
                      isSelected: currentTheme == AppThemeType.dark,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(AppThemeType.dark),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ThemeOption(
                      label: l10n.theme_claude,
                      icon: Icons.auto_awesome_rounded,
                      isSelected: currentTheme == AppThemeType.claude,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(AppThemeType.claude),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primary.withValues(alpha: 0.10)
                : theme.scaffoldBackgroundColor.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? primary : _outlineColor(context, alpha: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: 0.14)
                      : _panelColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? primary : _mutedColor(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? primary : null,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: isSelected ? primary : _mutedColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
