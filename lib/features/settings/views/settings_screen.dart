import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind/features/sidebar/sidebar_widget.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/models/enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../conversations/providers/conversation_providers.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../../servers/providers/server_providers.dart';
import '../data/models/app_settings.dart';
import '../../personas/providers/personas_providers.dart';

class SettingsViews extends ConsumerWidget {
  const SettingsViews({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: SidebarWidget(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader(title: 'Appearance'),
          _ThemeToggle(current: settings.themeMode, ref: ref),
          _SliderSetting(
            label: 'Font Size',
            value: settings.fontSize,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            description: 'Adjust text size in chat.',
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setFontSize(v),
            isDark: isDark,
            valueFormat: (v) => v.toStringAsFixed(0),
            previewText: 'The quick brown fox jumps over the lazy dog.',
          ),
          _CodeThemeDropdown(
            label: 'Code Theme (Dark)',
            current: settings.codeThemeDark,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setCodeThemeDark(v),
            isDark: isDark,
          ),
          _CodeThemeDropdown(
            label: 'Code Theme (Light)',
            current: settings.codeThemeLight,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setCodeThemeLight(v),
            isDark: isDark,
          ),
          const Divider(height: 32),
          _SectionHeader(title: 'Text-to-Speech'),
          _EngineDropdown(
            current: settings.ttsEngine,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setTtsEngine(v),
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.ttsModels),
              icon: const Icon(Icons.record_voice_over, size: 18),
              label: const Text('Manage TTS Models'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (settings.ttsEngine != EngineId.system) ...[
            const SizedBox(height: 8),
            _VoiceSelector(
              engine: settings.ttsEngine,
              currentVoiceId: settings.ttsVoiceId,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setTtsVoiceId(v?.id),
              isDark: isDark,
            ),
            _SliderSetting(
              label: 'TTS Speed',
              value: settings.ttsSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              description: 'Adjust the playback rate.',
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setTtsSpeed(v),
              isDark: isDark,
              valueFormat: (v) => '${v.toStringAsFixed(2)}x',
            ),
          ],
          const Divider(height: 32),
          _SectionHeader(title: 'Behavior'),
          _ToggleSetting(
            label: 'Streaming Responses',
            value: settings.streamingEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setStreamingEnabled(v),
            isDark: isDark,
          ),
          _ToggleSetting(
            label: 'Auto-generate Titles',
            value: settings.autoGenerateTitle,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setAutoGenerateTitle(v),
            isDark: isDark,
          ),
          _ToggleSetting(
            label: 'Send on Enter',
            value: settings.sendOnEnter,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setSendOnEnter(v),
            isDark: isDark,
          ),
          _ToggleSetting(
            label: 'Show System Messages',
            value: settings.showSystemMessages,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setShowSystemMessages(v),
            isDark: isDark,
          ),
          _ToggleSetting(
            label: 'Haptic Feedback',
            value: settings.hapticFeedbackEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setHapticFeedback(v),
            isDark: isDark,
          ),
          _ToggleSetting(
            label: 'Enable MCP',
            value: settings.mcpEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setMcpEnabled(v),
            isDark: isDark,
          ),
          if (settings.mcpEnabled)
            _ToggleSetting(
              label: 'New Chat MCP Default',
              value: settings.newChatMcpEnabled,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setNewChatMcpEnabled(v),
              isDark: isDark,
            ),
          const Divider(height: 32),
          _SectionHeader(title: 'On-Device Inference'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.onDeviceModels),
              icon: const Icon(Icons.phone_android, size: 18),
              label: const Text('Manage On-Device Models'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const _OnDeviceOnDeviceEngineStatus(),
          const Divider(height: 32),
          _SectionHeader(title: 'Default Server'),
          _DropdownSetting(
            label: 'Default Server',
            currentValue: settings.defaultServerId,
            items: (ref.watch(serversProvider).value ?? [])
                .map((s) => (s.id, s.name))
                .toList(),
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setDefaultServer(v),
            isDark: isDark,
            icon: Icons.computer,
          ),
          const Divider(height: 32),
          _SectionHeader(title: 'Default Persona'),
          _DropdownSetting(
            label: 'Default Persona',
            currentValue: settings.defaultPersonaId,
            items: (ref.watch(personasNotifierProvider).value ?? [])
                .map((p) => (p.id, '${p.emoji} ${p.name}'))
                .toList(),
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setDefaultPersona(v),
            isDark: isDark,
            icon: Icons.smart_toy_outlined,
          ),
          const Divider(height: 32),
          _SectionHeader(title: 'Privacy'),
          _ToggleSetting(
            label: 'Show Data Indicator',
            value: settings.showDataIndicator,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setShowDataIndicator(v),
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              '"LocalMind never sees your data"',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF888888)
                    : const Color(0xFF999999),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Divider(height: 32),
          _SectionHeader(title: 'Data Management'),
          _DangerousAction(
            label: 'Delete All Conversations',
            icon: Icons.delete_outline,
            onConfirm: () =>
                ref.read(conversationsProvider.notifier).deleteAll(),
            isDark: isDark,
          ),
          _DangerousAction(
            label: 'Reset Settings to Defaults',
            icon: Icons.restore,
            onConfirm: () =>
                ref.read(settingsProvider.notifier).resetToDefaults(),
            isDark: isDark,
          ),
          const Divider(height: 32),
          _SectionHeader(title: 'About'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'LocalMind v1.0.0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Your AI. Your Device. Your Rules.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF888888)
                    : const Color(0xFF999999),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF888888) : const Color(0xFF999999),
        ),
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
    required this.isDark,
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
  final bool isDark;
  final String Function(double)? valueFormat;
  final String? previewText;

  @override
  Widget build(BuildContext context) {
    final displayValue = valueFormat != null
        ? valueFormat!(value)
        : value.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: isDark
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF2563EB),
              thumbColor: isDark
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF2563EB),
              inactiveTrackColor: isDark
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFFE5E5E5),
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
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
            ),
          ),
          if (previewText != null) ...[
            const SizedBox(height: 4),
            Text(
              previewText!,
              style: TextStyle(
                fontSize: value.clamp(12, 24),
                color: isDark
                    ? const Color(0xFF888888)
                    : const Color(0xFF666666),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _IntInputSetting extends StatefulWidget {
  const _IntInputSetting({
    required this.label,
    required this.value,
    required this.description,
    required this.onChanged,
    required this.isDark,
  });

  final String label;
  final int value;
  final String description;
  final ValueChanged<int> onChanged;
  final bool isDark;

  @override
  State<_IntInputSetting> createState() => _IntInputSettingState();
}

class _IntInputSettingState extends State<_IntInputSetting> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_IntInputSetting old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (text) {
                final val = int.tryParse(text);
                if (val != null && val > 0) widget.onChanged(val);
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 12,
              color: widget.isDark
                  ? const Color(0xFF666666)
                  : const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
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
    required this.isDark,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.current, required this.ref});
  final ThemeMode current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentType = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ThemeOption(
                label: 'System',
                icon: Icons.brightness_auto,
                isSelected: currentType == AppThemeType.system,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeType.system),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode,
                isSelected: currentType == AppThemeType.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeType.light),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode,
                isSelected: currentType == AppThemeType.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeType.dark),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _ThemeOption(
                label: 'Claude',
                icon: Icons.auto_awesome,
                isSelected: currentType == AppThemeType.claude,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(AppThemeType.claude),
                isDark: isDark,
              ),
            ],
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
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.15)
                : (isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? accent
                  : (isDark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE5E5E5)),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? accent
                    : (isDark
                          ? const Color(0xFF888888)
                          : const Color(0xFF999999)),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? accent
                      : (isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF999999)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  const _DropdownSetting({
    required this.label,
    required this.currentValue,
    required this.items,
    required this.onChanged,
    required this.isDark,
    required this.icon,
  });

  final String label;
  final String? currentValue;
  final List<(String id, String name)> items;
  final ValueChanged<String?> onChanged;
  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            borderRadius: BorderRadius.circular(8),
            dropdownColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            hint: Text(
              'None selected',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF666666)
                    : const Color(0xFF999999),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  'None',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF888888)
                        : const Color(0xFF666666),
                  ),
                ),
              ),
              ...items.map(
                (item) => DropdownMenuItem(
                  value: item.$1,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF999999),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
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
    );
  }
}

class _CodeThemeDropdown extends StatelessWidget {
  const _CodeThemeDropdown({
    required this.label,
    required this.current,
    required this.onChanged,
    required this.isDark,
  });

  final String label;
  final SyntaxThemeName current;
  final ValueChanged<SyntaxThemeName> onChanged;
  final bool isDark;

  String _getDisplayName(SyntaxThemeName theme) {
    switch (theme) {
      case SyntaxThemeName.light:
        return 'Light';
      case SyntaxThemeName.dark:
        return 'Dark';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFE5E5E5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SyntaxThemeName>(
                value: current,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                borderRadius: BorderRadius.circular(8),
                dropdownColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                items: SyntaxThemeName.values.map((theme) {
                  return DropdownMenuItem(
                    value: theme,
                    child: Text(
                      _getDisplayName(theme),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose syntax highlighting theme for code blocks.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
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
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final VoidCallback onConfirm;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(label),
              content: const Text(
                'Are you sure? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onConfirm();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$label completed')));
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          );
        },
        icon: Icon(icon, color: Colors.red, size: 18),
        label: Text(label, style: const TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _EngineDropdown extends StatelessWidget {
  const _EngineDropdown({
    required this.current,
    required this.onChanged,
    required this.isDark,
  });

  final EngineId current;
  final ValueChanged<EngineId> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TTS Engine',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFE5E5E5),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EngineId>(
                value: current,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                borderRadius: BorderRadius.circular(8),
                dropdownColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                items: [
                  _engineItem(
                    EngineId.system,
                    'System TTS',
                    Icons.record_voice_over,
                  ),
                  _engineItem(
                    EngineId.kitten,
                    'Kitten TTS',
                    Icons.auto_awesome,
                  ),
                  _engineItem(
                    EngineId.kokoro,
                    'Kokoro TTS',
                    Icons.auto_awesome,
                  ),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<EngineId> _engineItem(
    EngineId id,
    String label,
    IconData icon,
  ) {
    final meta = EngineMeta.forEngine(id);
    return DropdownMenuItem(
      value: id,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(meta.accentColor)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
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
    required this.isDark,
  });

  final EngineId engine;
  final String? currentVoiceId;
  final ValueChanged<Voice?> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final voices = voicesForEngine(engine);

    if (voices.isEmpty) return const SizedBox.shrink();

    final femaleVoices = voices.where((v) => v.gender == 'f').toList();
    final maleVoices = voices.where((v) => v.gender == 'm').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          if (femaleVoices.isNotEmpty) ...[
            Text(
              'Female',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF888888)
                    : const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 4),
            ...femaleVoices.map(
              (v) => _VoiceTile(
                voice: v,
                selected: v.id == currentVoiceId,
                onTap: () => onChanged(v),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (maleVoices.isNotEmpty) ...[
            Text(
              'Male',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF888888)
                    : const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 4),
            ...maleVoices.map(
              (v) => _VoiceTile(
                voice: v,
                selected: v.id == currentVoiceId,
                onTap: () => onChanged(v),
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    required this.voice,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final Voice voice;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.1)
                : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? accent
                  : (isDark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE5E5E5)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: selected
                    ? accent
                    : (isDark
                          ? const Color(0xFF666666)
                          : const Color(0xFF999999)),
              ),
              const SizedBox(width: 8),
              Text(
                voice.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (voice.language != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    voice.language!,
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark
                          ? const Color(0xFF888888)
                          : const Color(0xFF666666),
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

class _OnDeviceOnDeviceEngineStatus extends ConsumerWidget {
  const _OnDeviceOnDeviceEngineStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engineState = ref.watch(onDeviceEngineProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (engineState.status == OnDeviceEngineStatus.notLoaded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          'No model loaded. Tap "Manage On-Device Models" to download and load a model.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: engineState.status == OnDeviceEngineStatus.loaded
              ? Colors.green.withValues(alpha: 0.1)
              : engineState.status == OnDeviceEngineStatus.error
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: engineState.status == OnDeviceEngineStatus.loaded
                ? Colors.green
                : engineState.status == OnDeviceEngineStatus.error
                ? Colors.red
                : Colors.blue,
          ),
        ),
        child: Row(
          children: [
            Icon(
              engineState.status == OnDeviceEngineStatus.loaded
                  ? Icons.check_circle
                  : engineState.status == OnDeviceEngineStatus.error
                  ? Icons.error
                  : Icons.hourglass_top,
              size: 18,
              color: engineState.status == OnDeviceEngineStatus.loaded
                  ? Colors.green
                  : engineState.status == OnDeviceEngineStatus.error
                  ? Colors.red
                  : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                engineState.status == OnDeviceEngineStatus.loaded
                    ? 'Loaded: ${engineState.loadedModelId ?? "unknown"} (${engineState.backend?.name ?? "CPU"})'
                    : engineState.status == OnDeviceEngineStatus.loading
                    ? 'Loading model...'
                    : 'Error: ${engineState.error ?? "Unknown error"}',
                style: TextStyle(
                  fontSize: 13,
                  color: engineState.status == OnDeviceEngineStatus.loaded
                      ? Colors.green
                      : engineState.status == OnDeviceEngineStatus.error
                      ? Colors.red
                      : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
