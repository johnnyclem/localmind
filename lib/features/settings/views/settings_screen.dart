import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:localmind/l10n/app_localizations.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/system_insets.dart';
import '../../conversations/providers/conversation_providers.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../../personas/providers/personas_providers.dart';
import '../../servers/providers/server_providers.dart';
import '../data/models/app_settings.dart';

part 'settings_screen_layout_parts.dart';
part 'settings_screen_controls_parts.dart';
part 'settings_screen_extras_parts.dart';
part 'settings_screen_parts.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SettingsContent();
  }
}
