import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/models/hypervault_capabilities.dart';
import '../../../../core/network/hypervault_api_exception.dart';
import '../../data/models/claimed_domain.dart';
import '../../providers/domains_providers.dart';

/// Restyles a *claimed* realm — visitor-facing, `PATCH /api/claim-domain`
/// (mobile PRD T-M13-07).
Future<void> showRealmThemePickerSheet(
  BuildContext context,
  WidgetRef ref,
  ClaimedDomain claimed,
  List<HyperVaultTheme> themes,
) {
  return _showThemePickerSheet(
    context,
    title: 'Restyle ${claimed.domain}',
    themes: themes,
    currentThemeId: claimed.theme,
    onSelect: (themeId) => ref
        .read(claimedDomainsProvider.notifier)
        .restyle(domain: claimed.domain, themeId: themeId),
  );
}

/// Restyles the signed-in user's own dashboard surfaces — `PATCH
/// /api/dashboard-theme` (mobile PRD T-M13-08).
Future<void> showDashboardThemePickerSheet(
  BuildContext context,
  WidgetRef ref,
  List<HyperVaultTheme> themes,
  String? currentThemeId,
) {
  return _showThemePickerSheet(
    context,
    title: 'My dashboard theme',
    themes: themes,
    currentThemeId: currentThemeId,
    onSelect: (themeId) =>
        ref.read(dashboardThemeProvider.notifier).setTheme(themeId),
  );
}

Future<void> _showThemePickerSheet(
  BuildContext context, {
  required String title,
  required List<HyperVaultTheme> themes,
  required String? currentThemeId,
  required Future<void> Function(String themeId) onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ThemePickerSheetBody(
      title: title,
      themes: themes,
      currentThemeId: currentThemeId,
      onSelect: onSelect,
    ),
  );
}

class _ThemePickerSheetBody extends StatefulWidget {
  final String title;
  final List<HyperVaultTheme> themes;
  final String? currentThemeId;
  final Future<void> Function(String themeId) onSelect;

  const _ThemePickerSheetBody({
    required this.title,
    required this.themes,
    required this.currentThemeId,
    required this.onSelect,
  });

  @override
  State<_ThemePickerSheetBody> createState() => _ThemePickerSheetBodyState();
}

class _ThemePickerSheetBodyState extends State<_ThemePickerSheetBody> {
  String? _busyId;
  String? _error;

  Future<void> _pick(String themeId) async {
    setState(() {
      _busyId = themeId;
      _error = null;
    });
    try {
      await widget.onSelect(themeId);
      if (mounted) Navigator.pop(context);
    } on HyperVaultApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyId = null;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                _error!,
                style: TextStyle(color: colorScheme.error, fontSize: 13),
              ),
            ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.themes.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No themes available.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ]
                    : widget.themes.map((t) {
                        final isCurrent = t.id == widget.currentThemeId;
                        final isBusy = _busyId == t.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: _busyId != null ? null : () => _pick(t.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? colorScheme.primary.withAlpha(20)
                                    : colorScheme.surfaceContainerHighest
                                          .withAlpha(80),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrent
                                      ? colorScheme.primary.withAlpha(100)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: t.mode == 'light'
                                        ? HugeIcons.strokeRoundedSun01
                                        : HugeIcons.strokeRoundedMoon,
                                    size: 20,
                                    color: isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.name,
                                          style: TextStyle(
                                            fontWeight: isCurrent
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isCurrent
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          t.mode,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isCurrent
                                                ? colorScheme.primary
                                                      .withAlpha(150)
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isBusy)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else if (isCurrent)
                                    HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedCheckmarkCircle01,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
