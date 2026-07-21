import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/models/hypervault_capabilities.dart';
import '../../providers/domains_providers.dart';
import 'theme_picker_sheet.dart';

/// T-M13-08: theme picker for the signed-in user's own dashboard surfaces —
/// independent of any claimed realm.
class DashboardThemeCard extends ConsumerWidget {
  final List<HyperVaultTheme> themes;

  const DashboardThemeCard({super.key, required this.themes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentThemeId = ref.watch(dashboardThemeProvider);

    String currentName = 'Default';
    for (final t in themes) {
      if (t.id == currentThemeId) {
        currentName = t.name;
        break;
      }
    }

    return ShadCard(
      title: const Text('My dashboard theme'),
      description: const Text(
        'Restyles your own signed-in surfaces — not any claimed realm.',
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedPaintBoard,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ShadButton.outline(
              onPressed: () => showDashboardThemePickerSheet(
                context,
                ref,
                themes,
                currentThemeId,
              ),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}
