import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/crash_report_service.dart';

/// User-facing fallback shown when a crash is captured. Used both as
/// `ErrorWidget.builder` and from `main.dart`'s `ValueListenableBuilder`
/// that wraps `BootstrapHost`.
class CrashErrorWidget extends StatelessWidget {
  const CrashErrorWidget({super.key, required this.crash});

  final CrashReport crash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stackLines = crash.stackTrace.toString().split('\n');
    final previewLines = stackLines.take(40).join('\n');

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 36,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'v${crash.appVersion} (${crash.buildNumber}) · ${crash.platform} ${crash.deviceModel}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bug_report_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                crash.errorType,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          crash.shortError,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        'Stack trace',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Tap to expand',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: SelectableText(
                            previewLines.isEmpty ? '<empty>' : previewLines,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _openGitHub(context),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Report this crash'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _tryAgain(context),
                    child: const Text('Try again'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reporting opens GitHub with diagnostics prefilled. '
                    'You stay in control — nothing is submitted automatically. '
                    'Please review and remove any sensitive content before submitting.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openGitHub(BuildContext context) async {
    final uri = CrashReportService.instance.buildGitHubIssueUrl(crash);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && messenger != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open GitHub. Please copy the URL manually.',
            ),
          ),
        );
      }
    } catch (e) {
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to open URL: $e')),
        );
      }
    }
  }

  void _tryAgain(BuildContext context) {
    CrashReportService.instance.clearCrash();
  }
}
