import 'package:flutter/material.dart';
import 'package:localmind/l10n/app_localizations.dart';

class TemporaryChatBanner extends StatelessWidget {
  const TemporaryChatBanner({
    super.key,
    required this.onSaveToHistory,
  });

  final VoidCallback onSaveToHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2418)
            : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6B5A2E)
              : const Color(0xFFE6C35C),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty_outlined,
            size: 18,
            color: isDark ? const Color(0xFFE6C35C) : const Color(0xFF9A7B1A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.temporary_chat_banner,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF5E6B8) : const Color(0xFF5C4A12),
              ),
            ),
          ),
          TextButton(
            onPressed: onSaveToHistory,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              l10n.save_to_history,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFE6C35C) : const Color(0xFF9A7B1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
