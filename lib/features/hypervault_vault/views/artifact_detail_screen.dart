import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../data/hv_vault_format.dart';
import '../data/models/hv_artifact.dart';
import '../providers/hv_vault_providers.dart';
import 'components/connections_section.dart';
import 'components/connect_picker_sheet.dart';
import 'components/share_invite_panel.dart';
import 'components/view_source_sheet.dart';

/// Full artifact detail + actions (docs/mobile/prd/03-vault-artifacts.md
/// item 2 / T-M3-05/06/11/12, 05-connections-sharing.md T-M5-01..04).
class ArtifactDetailScreen extends ConsumerWidget {
  final HvArtifact artifact;

  const ArtifactDetailScreen({super.key, required this.artifact});

  Future<void> _toggleVisibility(BuildContext context, WidgetRef ref, HvArtifact current) async {
    final next = current.isPrivate ? 'public' : 'private';
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(hvArtifactsProvider.notifier).setVisibility(current.slug, next);
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, HvArtifact current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete artifact?'),
        content: Text('“${current.title}” will be gone for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(hvArtifactsProvider.notifier).removeArtifact(current.slug);
      if (context.mounted) Navigator.pop(context);
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    }
  }

  Future<void> _open(HvArtifact current) async {
    final uri = Uri.tryParse(current.url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _share(HvArtifact current) async {
    await SharePlus.instance.share(
      ShareParams(text: current.url, subject: current.title),
    );
  }

  Future<void> _setFeedback(
    BuildContext context,
    WidgetRef ref,
    HvArtifact current,
    String? feedback,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(hvVaultServiceProvider).setFeedback(current.slug, feedback);
      ref.invalidate(hvArtifactFeedbackProvider(current.slug));
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artifacts = ref.watch(hvArtifactsProvider).value ?? const <HvArtifact>[];
    final current = artifacts.where((a) => a.slug == artifact.slug).firstOrNull ?? artifact;
    final feedbackAsync = ref.watch(hvArtifactFeedbackProvider(current.slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(current.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InkWell(
                    onTap: () => showViewSourceSheet(context, current.slug),
                    child: ShadBadge(
                      backgroundColor: hvArtifactTypeColor(current.type, isJsx: current.isJsx)
                          .withValues(alpha: 0.15),
                      foregroundColor: hvArtifactTypeColor(current.type, isJsx: current.isJsx),
                      child: Text('${current.type} · view source'),
                    ),
                  ),
                  if (current.isJsx) const ShadBadge.secondary(child: Text('React · auto-wrapped')),
                  if (current.isPwa) const ShadBadge.outline(child: Text('Installable')),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Saved ${hvRelativeTime(current.createdAt)}',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
              if (current.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: current.tags
                      .map((t) => Text('#$t', style: const TextStyle(fontFamily: 'monospace')))
                      .toList(),
                ),
              ],
              if ((current.sourcePrompt ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('💬 Source prompt', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text('“${current.sourcePrompt}”', style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ShadButton(
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedSquareArrowUpRight, size: 16),
                    onPressed: () => _open(current),
                    child: const Text('Open'),
                  ),
                  ShadButton.outline(
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedShare08, size: 16),
                    onPressed: () => _share(current),
                    child: const Text('Share'),
                  ),
                  ShadButton.outline(
                    leading: HugeIcon(
                      icon: current.isPrivate
                          ? HugeIcons.strokeRoundedLockKey
                          : HugeIcons.strokeRoundedGlobe02,
                      size: 16,
                    ),
                    onPressed: () => _toggleVisibility(context, ref, current),
                    child: Text(current.isPrivate ? 'Private' : 'Public'),
                  ),
                  ShadButton.destructive(
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 16),
                    onPressed: () => _delete(context, ref, current),
                    child: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Feedback', style: theme.textTheme.titleSmall),
                  const SizedBox(width: 12),
                  feedbackAsync.when(
                    data: (feedback) => Row(
                      children: [
                        IconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedThumbsUp,
                            color: feedback == 'up' ? Colors.green : null,
                          ),
                          onPressed: () => _setFeedback(
                            context,
                            ref,
                            current,
                            feedback == 'up' ? null : 'up',
                          ),
                        ),
                        IconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedThumbsDown,
                            color: feedback == 'down' ? Colors.red : null,
                          ),
                          onPressed: () => _setFeedback(
                            context,
                            ref,
                            current,
                            feedback == 'down' ? null : 'down',
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(child: Text('Connections', style: theme.textTheme.titleSmall)),
                  ShadButton.ghost(
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedLinkSquare01, size: 16),
                    onPressed: () => showConnectPickerSheet(context, source: current),
                    child: const Text('Connect'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConnectionsSection(artifact: current),
              const Divider(height: 32),
              Text('Sharing', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ShareInvitePanel(artifactRef: current.slug),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
