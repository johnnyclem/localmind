import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import '../../settings/data/models/app_settings.dart';
import '../data/kitten_tts_model.dart';
import '../data/piper_tts_model.dart';
import '../providers/tts_model_providers.dart';
import '../providers/tts_providers.dart' as tts;

part 'tts_model_manager_screen_parts.dart';

class TtsModelManagerScreen extends ConsumerWidget {
  const TtsModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                  l10n.tts_models_title,
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SystemEngineCard(isSelected: settings.ttsEngine == EngineId.system),
                const SizedBox(height: 16),
                _KittenEngineCard(isSelected: settings.ttsEngine == EngineId.kitten),
                const SizedBox(height: 16),
                _PiperEngineCard(isSelected: settings.ttsEngine == EngineId.piper),
                const SizedBox(height: 24),
              ],
            ),
          ),
      ],
    );
  }
}

// ── System Engine ──
