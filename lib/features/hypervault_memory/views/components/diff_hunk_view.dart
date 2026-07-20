import 'package:flutter/material.dart';

import '../../data/models/hv_mind_diff.dart';

/// Renders line-level diff hunks: `+` add (green), `-` del (red), context
/// (muted). Handles `oversize` and empty-hunks states per T-M7-07.
class DiffHunkView extends StatelessWidget {
  final HvTextDiff diff;

  const DiffHunkView({super.key, required this.diff});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    if (diff.oversize) {
      return Text(
        'content replaced — too large to diff line by line',
        style: TextStyle(
          fontSize: 12,
          color: muted,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    if (diff.hunks.isEmpty) {
      return Text(
        'no content change — title or tags only',
        style: TextStyle(
          fontSize: 12,
          color: muted,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final hunk in diff.hunks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@@ -${hunk.oldStart},${hunk.oldLines} +${hunk.newStart},${hunk.newLines} @@',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                  for (final line in hunk.lines)
                    Text(
                      '${line.isAdd
                          ? '+'
                          : line.isDel
                          ? '-'
                          : ' '} ${line.text}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.4,
                        color: line.isAdd
                            ? Colors.green.shade600
                            : line.isDel
                            ? Colors.red.shade600
                            : muted,
                        backgroundColor: line.isAdd
                            ? Colors.green.withValues(alpha: 0.08)
                            : line.isDel
                            ? Colors.red.withValues(alpha: 0.08)
                            : null,
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
