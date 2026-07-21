import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/models/import_history_result.dart';

/// Success summary shown after `POST /api/import` returns (mobile PRD
/// T-M12-05): imported/skipped counts, the server's `message`, and — if the
/// server ever reports `messages` as a list rather than a count — a bulleted
/// list of those entries.
class ImportResultCard extends StatelessWidget {
  final ImportHistoryResult result;

  const ImportResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Imported ${result.imported}, skipped ${result.skipped}'
                  '${result.messageCount != null ? ' (${result.messageCount} messages)' : ''}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (result.message != null && result.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (result.messages != null && result.messages!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...result.messages!.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: theme.textTheme.bodySmall),
                    Expanded(child: Text(m, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
