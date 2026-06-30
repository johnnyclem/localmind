part of 'settings_screen.dart';

class _DropdownSetting extends StatelessWidget {
  const _DropdownSetting({
    required this.label,
    required this.currentValue,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  final String label;
  final String? currentValue;
  final List<(String id, String name)> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingHeader(label: label),
          const SizedBox(height: 10),
          _InputShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: currentValue,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: theme.colorScheme.surface,
                hint: Text(
                  l10n.none_selected,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _mutedColor(context),
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.none),
                  ),
                  ...items.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.$1,
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: _mutedColor(context)),
                          const SizedBox(width: 8),
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

class _CodeThemeDropdown extends StatelessWidget {
  const _CodeThemeDropdown({
    required this.label,
    required this.current,
    required this.onChanged,
  });

  final String label;
  final SyntaxThemeName current;
  final ValueChanged<SyntaxThemeName> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingHeader(label: label),
          const SizedBox(height: 10),
          _InputShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SyntaxThemeName>(
                value: current,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: theme.colorScheme.surface,
                items: SyntaxThemeName.values.map((codeTheme) {
                  final displayName = switch (codeTheme) {
                    SyntaxThemeName.light => l10n.theme_light,
                    SyntaxThemeName.dark => l10n.theme_dark,
                  };

                  return DropdownMenuItem<SyntaxThemeName>(
                    value: codeTheme,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.code_theme_desc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _mutedColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerousAction extends StatelessWidget {
  const _DangerousAction({
    required this.label,
    required this.icon,
    required this.onConfirm,
  });

  final String label;
  final IconData icon;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton.icon(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) {
            final dialogL10n = AppLocalizations.of(dialogContext)!;
            return AlertDialog(
              title: Text(label),
              content: Text(dialogL10n.cannot_undo),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(dialogL10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onConfirm();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.label_completed(label))),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(dialogL10n.confirm),
                ),
              ],
            );
          },
        );
      },
      icon: Icon(icon, color: Colors.red, size: 16),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: const TextStyle(color: Colors.red)),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: BorderSide(color: Colors.red.withValues(alpha: 0.55)),
        minimumSize: const Size(double.infinity, 44),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionActionButton extends StatelessWidget {
  const _SectionActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ShadButton.outline(
      onPressed: onPressed,
      width: double.infinity,
      leading: Icon(icon, size: 16),
      child: Align(alignment: Alignment.centerLeft, child: Text(label)),
    );
  }
}

class _EngineDropdown extends StatelessWidget {
  const _EngineDropdown({required this.current, required this.onChanged});

  final EngineId current;
  final ValueChanged<EngineId> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingHeader(label: l10n.tts_engine),
          const SizedBox(height: 10),
          _InputShell(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EngineId>(
                value: current,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: theme.colorScheme.surface,
                items: [
                  _engineItem(
                    context,
                    EngineId.system,
                    l10n.tts_engine_system,
                    Icons.record_voice_over_rounded,
                  ),
                  _engineItem(
                    context,
                    EngineId.kitten,
                    l10n.tts_engine_kitten,
                    Icons.auto_awesome_rounded,
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<EngineId> _engineItem(
    BuildContext context,
    EngineId id,
    String label,
    IconData icon,
  ) {
    final meta = EngineMeta.forEngine(id);
    return DropdownMenuItem<EngineId>(
      value: id,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Color(meta.accentColor)),
          const SizedBox(width: 10),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _VoiceSelector extends StatelessWidget {
  const _VoiceSelector({
    required this.engine,
    required this.currentVoiceId,
    required this.onChanged,
  });

  final EngineId engine;
  final String? currentVoiceId;
  final ValueChanged<Voice?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final voices = voicesForEngine(engine);
    final resolvedCurrentVoiceId = voiceFromSettings(
      currentVoiceId,
      engine,
    )?.id;

    if (voices.isEmpty) {
      return const SizedBox.shrink();
    }

    final femaleVoices = voices.where((voice) => voice.gender == 'f').toList();
    final maleVoices = voices.where((voice) => voice.gender == 'm').toList();
    final otherVoices = voices
        .where((voice) => voice.gender != 'f' && voice.gender != 'm')
        .toList();

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingHeader(label: l10n.voice),
          if (femaleVoices.isNotEmpty) ...[
            const SizedBox(height: 8),
            _VoiceGroup(
              title: l10n.voice_female,
              voices: femaleVoices,
              selectedVoiceId: resolvedCurrentVoiceId,
              onChanged: onChanged,
            ),
          ],
          if (maleVoices.isNotEmpty) ...[
            const SizedBox(height: 12),
            _VoiceGroup(
              title: l10n.voice_male,
              voices: maleVoices,
              selectedVoiceId: resolvedCurrentVoiceId,
              onChanged: onChanged,
            ),
          ],
          if (otherVoices.isNotEmpty) ...[
            const SizedBox(height: 12),
            _VoiceGroup(
              title: l10n.voice_other,
              voices: otherVoices,
              selectedVoiceId: resolvedCurrentVoiceId,
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceGroup extends StatelessWidget {
  const _VoiceGroup({
    required this.title,
    required this.voices,
    required this.selectedVoiceId,
    required this.onChanged,
  });

  final String title;
  final List<Voice> voices;
  final String? selectedVoiceId;
  final ValueChanged<Voice?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _mutedColor(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: voices
              .map(
                (voice) => _VoiceChip(
                  voice: voice,
                  selected: voice.id == selectedVoiceId,
                  onTap: () => onChanged(voice),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _VoiceChip extends StatelessWidget {
  const _VoiceChip({
    required this.voice,
    required this.selected,
    required this.onTap,
  });

  final Voice voice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.10)
                : theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary : _outlineColor(context, alpha: 0.8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 16,
                color: selected ? primary : _mutedColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                voice.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? primary : null,
                ),
              ),
              if (voice.language != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _panelColor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    voice.language!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _mutedColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OnDeviceEngineStatusCard extends ConsumerWidget {
  const _OnDeviceEngineStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final engineState = ref.watch(onDeviceEngineProvider);

    final (
      Color accent,
      IconData icon,
      String message,
    ) = switch (engineState.status) {
      OnDeviceEngineStatus.loaded => (
        Colors.green,
        Icons.check_circle_rounded,
        l10n.model_loaded(
          engineState.loadedModelId ?? 'unknown',
          engineState.backend?.name ?? 'CPU',
        ),
      ),
      OnDeviceEngineStatus.loading => (
        Colors.blue,
        Icons.hourglass_top_rounded,
        l10n.loading,
      ),
      OnDeviceEngineStatus.error => (
        Colors.red,
        Icons.error_rounded,
        l10n.error_with_message(engineState.error ?? l10n.unknown_error),
      ),
      OnDeviceEngineStatus.notLoaded => (
        Colors.grey,
        Icons.info_outline_rounded,
        l10n.no_model_loaded,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingHeader extends StatelessWidget {
  const _SettingHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _InputShell extends StatelessWidget {
  const _InputShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _outlineColor(context, alpha: 0.8)),
      ),
      child: child,
    );
  }
}

class _HuggingFaceTokenSetting extends StatelessWidget {
  const _HuggingFaceTokenSetting({
    required this.currentToken,
    required this.onSave,
  });

  final String? currentToken;
  final ValueChanged<String?> onSave;

  bool get _hasToken => currentToken != null && currentToken!.isNotEmpty;

  String _maskedToken(String token) {
    if (token.length <= 6) return '••••••';
    return '${token.substring(0, 4)}••••••${token.substring(token.length - 4)}';
  }

  Future<void> _editToken(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentToken ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.edit_huggingface_token_dialog_title),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.huggingface_token_dialog_hint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: Text(l10n.clear_huggingface_token),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (result == null) return;
    onSave(result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _SettingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingHeader(label: l10n.settings_huggingface_token),
          const SizedBox(height: 6),
          Text(
            l10n.settings_huggingface_token_desc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _mutedColor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InputShell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Text(
                      _hasToken ? _maskedToken(currentToken!) : '—',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: _hasToken
                            ? theme.colorScheme.onSurface
                            : _mutedColor(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ShadButton.outline(
                onPressed: () => _editToken(context),
                child: Text(_hasToken ? l10n.edit : l10n.set_huggingface_token),
              ),
              if (_hasToken) ...[
                const SizedBox(width: 6),
                ShadButton.outline(
                  onPressed: () => onSave(null),
                  child: Text(l10n.clear_huggingface_token),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
