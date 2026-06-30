part of 'settings_screen.dart';

class SettingsContent extends ConsumerWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final settings = ref.watch(settingsProvider);
        final currentTheme = ref.watch(themeModeProvider);
        final systemBottomInset = bottomSystemInset(context);
        final packageInfo = ref.watch(packageInfoProvider);
        final servers = (ref.watch(serversProvider).value ?? [])
            .map((server) => (server.id, server.name))
            .toList();
        final personas = (ref.watch(personasNotifierProvider).value ?? [])
            .map((persona) => (persona.id, '${persona.emoji} ${persona.name}'))
            .toList();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final topPadding = MediaQuery.of(context).padding.top;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: topPadding + 8,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFE5E5E5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.settings_title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useTwoColumns = constraints.maxWidth >= 1080;
                  final contentMaxWidth = useTwoColumns ? 1120.0 : 720.0;
                  final horizontalPadding = constraints.maxWidth >= 720
                      ? 20.0
                      : 12.0;

                  final appearanceCard = _SettingsSectionCard(
                    title: l10n.settings_appearance,
                    icon: Icons.palette_outlined,
                    accent: const Color(0xFF8B5CF6),
                    children: [
                      _ThemeToggle(ref: ref),
                      _LanguageSetting(
                        current: settings.localeCode,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setLocaleCode(value),
                      ),
                      _SliderSetting(
                        label: l10n.font_size,
                        value: settings.fontSize,
                        min: 12.0,
                        max: 24.0,
                        divisions: 12,
                        description: l10n.font_size_desc,
                        onChanged: (value) =>
                            ref.read(settingsProvider.notifier).setFontSize(value),
                        valueFormat: (value) => value.toStringAsFixed(0),
                        previewText: l10n.font_preview,
                      ),
                      _CodeThemeDropdown(
                        label: l10n.code_theme_dark,
                        current: settings.codeThemeDark,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setCodeThemeDark(value),
                      ),
                      _CodeThemeDropdown(
                        label: l10n.code_theme_light,
                        current: settings.codeThemeLight,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setCodeThemeLight(value),
                      ),
                    ],
                  );

                  final ttsCard = _SettingsSectionCard(
                    title: l10n.settings_tts,
                    icon: Icons.graphic_eq_rounded,
                    accent: const Color(0xFF0EA5E9),
                    children: [
                      _EngineDropdown(
                        current: settings.ttsEngine,
                        onChanged: (value) =>
                            ref.read(settingsProvider.notifier).setTtsEngine(value),
                      ),
                      _SectionActionButton(
                        icon: Icons.record_voice_over_outlined,
                        label: l10n.manage_tts_models,
                        onPressed: () => context.push(AppRoutes.ttsModels),
                      ),
                      if (settings.ttsEngine != EngineId.system) ...[
                        _VoiceSelector(
                          engine: settings.ttsEngine,
                          currentVoiceId: settings.ttsVoiceId,
                          onChanged: (voice) => ref
                              .read(settingsProvider.notifier)
                              .setTtsVoiceId(voice?.id),
                        ),
                        _SliderSetting(
                          label: l10n.tts_speed,
                          value: settings.ttsSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          description: l10n.tts_speed_desc,
                          onChanged: (value) => ref
                              .read(settingsProvider.notifier)
                              .setTtsSpeed(value),
                          valueFormat: (value) => '${value.toStringAsFixed(2)}x',
                        ),
                      ],
                    ],
                  );

                  final behaviorCard = _SettingsSectionCard(
                    title: l10n.settings_behavior,
                    icon: Icons.tune_rounded,
                    accent: const Color(0xFF22C55E),
                    children: [
                      _ToggleSetting(
                        label: l10n.streaming_responses,
                        value: settings.streamingEnabled,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setStreamingEnabled(value),
                      ),
                      _ToggleSetting(
                        label: l10n.auto_generate_titles,
                        value: settings.autoGenerateTitle,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setAutoGenerateTitle(value),
                      ),
                      _ToggleSetting(
                        label: l10n.send_on_enter,
                        value: settings.sendOnEnter,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setSendOnEnter(value),
                      ),
                      _ToggleSetting(
                        label: l10n.show_system_messages,
                        value: settings.showSystemMessages,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setShowSystemMessages(value),
                      ),
                      _ToggleSetting(
                        label: l10n.haptic_feedback,
                        value: settings.hapticFeedbackEnabled,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setHapticFeedback(value),
                      ),
                      _ToggleSetting(
                        label: l10n.enable_mcp,
                        value: settings.mcpEnabled,
                        badges: [_FeatureBadge(label: l10n.experimental_label)],
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setMcpEnabled(value),
                      ),
                      if (settings.mcpEnabled)
                        _ToggleSetting(
                          label: l10n.new_chat_mcp_default,
                          value: settings.newChatMcpEnabled,
                          onChanged: (value) => ref
                              .read(settingsProvider.notifier)
                              .setNewChatMcpEnabled(value),
                        ),
                    ],
                  );

                  final onDeviceCard = _SettingsSectionCard(
                    title: l10n.settings_on_device,
                    icon: Icons.memory_rounded,
                    accent: const Color(0xFFF97316),
                    children: [
                      _ToggleSetting(
                        label: l10n.enable_smart_reply,
                        value: settings.smartReplyEnabled,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setSmartReplyEnabled(value),
                      ),
                      _HuggingFaceTokenSetting(
                        currentToken: settings.huggingFaceToken,
                        onSave: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .setHuggingFaceToken(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value == null || value.isEmpty
                                    ? l10n.settings_huggingface_token_cleared
                                    : l10n.settings_huggingface_token_set,
                              ),
                            ),
                          );
                        },
                      ),
                      _SectionActionButton(
                        icon: Icons.phone_android_rounded,
                        label: l10n.manage_on_device_models,
                        onPressed: () => context.push(AppRoutes.onDeviceModels),
                      ),
                      const _OnDeviceEngineStatusCard(),
                    ],
                  );

                  final defaultsCard = _SettingsSectionCard(
                    title: l10n.settings_default_server,
                    icon: Icons.hub_outlined,
                    accent: const Color(0xFF06B6D4),
                    children: [
                      _DropdownSetting(
                        label: l10n.settings_default_server,
                        currentValue: settings.defaultServerId,
                        items: servers,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setDefaultServer(value),
                        icon: Icons.computer_rounded,
                      ),
                      _DropdownSetting(
                        label: l10n.settings_default_persona,
                        currentValue: settings.defaultPersonaId,
                        items: personas,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setDefaultPersona(value),
                        icon: Icons.smart_toy_outlined,
                      ),
                    ],
                  );

                  final privacyCard = _SettingsSectionCard(
                    title: l10n.settings_privacy,
                    icon: Icons.lock_outline_rounded,
                    accent: const Color(0xFF14B8A6),
                    children: [
                      _ToggleSetting(
                        label: l10n.show_data_indicator,
                        value: settings.showDataIndicator,
                        onChanged: (value) => ref
                            .read(settingsProvider.notifier)
                            .setShowDataIndicator(value),
                      ),
                      _MutedCallout(message: l10n.privacy_info),
                    ],
                  );

                  final dataCard = _SettingsSectionCard(
                    title: l10n.settings_data_management,
                    icon: Icons.restore_page_outlined,
                    accent: const Color(0xFFEF4444),
                    children: [
                      _DangerousAction(
                        label: l10n.delete_all_conversations,
                        icon: Icons.delete_outline_rounded,
                        onConfirm: () =>
                            ref.read(conversationsProvider.notifier).deleteAll(),
                      ),
                      _DangerousAction(
                        label: l10n.reset_settings_defaults,
                        icon: Icons.restore_rounded,
                        onConfirm: () =>
                            ref.read(settingsProvider.notifier).resetToDefaults(),
                      ),
                    ],
                  );

                  final aboutCard = _SettingsSectionCard(
                    title: l10n.settings_about,
                    icon: Icons.info_outline_rounded,
                    accent: const Color(0xFFF59E0B),
                    children: [
                      _AboutPanel(
                        title:
                            '${l10n.app_name} v${packageInfo.value?.version ?? l10n.app_version} (${packageInfo.value?.buildNumber ?? ''})',
                        subtitle: l10n.onboarding_connect_desc.replaceAll(
                          '\n',
                          ' ',
                        ),
                        providers: [
                          l10n.server_type_lm_studio,
                          l10n.server_type_ollama,
                          l10n.server_type_openrouter,
                        ],
                        highlights: [
                          l10n.settings_on_device,
                          l10n.streaming_responses,
                          l10n.nav_personas,
                        ],
                        stack: const ['Flutter', 'Riverpod', 'shadcn_ui'],
                        openSource: l10n.open_source_desc,
                      ),
                    ],
                  );

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      24 + systemBottomInset,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentMaxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SettingsHero(
                                settings: settings,
                                themeType: currentTheme,
                              ),
                              const SizedBox(height: 16),
                              if (useTwoColumns)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _SettingsSectionColumn(
                                        children: [
                                          appearanceCard,
                                          behaviorCard,
                                          defaultsCard,
                                          privacyCard,
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: _SettingsSectionColumn(
                                        children: [
                                          ttsCard,
                                          onDeviceCard,
                                          dataCard,
                                          aboutCard,
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                _SettingsSectionColumn(
                                  children: [
                                    appearanceCard,
                                    ttsCard,
                                    behaviorCard,
                                    onDeviceCard,
                                    defaultsCard,
                                    privacyCard,
                                    dataCard,
                                    aboutCard,
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
  }
}

class _SettingsSectionColumn extends StatelessWidget {
  const _SettingsSectionColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _withVerticalSpacing(children, gap: 16),
    );
  }
}
