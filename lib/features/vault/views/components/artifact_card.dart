import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../../../core/providers/artifact_identity_providers.dart';
import '../../../../core/services/share_service.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../connections/providers/connections_providers.dart';
import '../../../connections/views/connect_sheet.dart';
import '../../data/models/artifact.dart';
import '../../providers/vault_providers.dart';
import 'source_sheet.dart';

/// Renders a coarse, human-friendly relative timestamp ("just now", "5m
/// ago", "3d ago", falling back to a locale date past ~4 weeks). No
/// dependency is added for this — it is intentionally simple.
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}

/// One artifact row on the vault list (mobile PRD T-M3-02): title, visibility
/// toggle, type/status badges (including a connection-count badge sourced
/// from the shared identity-cache-aware connections lookup — see
/// `lib/core/storage/artifact_identity_cache.dart`), tag chips, a
/// collapsible source-prompt disclosure, and an inline action row (view
/// source, open, share, connect, delete) so common actions don't require a
/// trip through the detail screen.
class ArtifactCard extends ConsumerStatefulWidget {
  final Artifact artifact;
  final VoidCallback onTap;

  const ArtifactCard({super.key, required this.artifact, required this.onTap});

  @override
  ConsumerState<ArtifactCard> createState() => _ArtifactCardState();
}

class _ArtifactCardState extends ConsumerState<ArtifactCard> {
  bool _promptExpanded = false;

  void _showError(Object e) {
    final message = e is HyperVaultApiException ? e.message : e.toString();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleVisibility() async {
    final artifact = widget.artifact;
    final next = artifact.isPublic ? 'private' : 'public';
    try {
      await ref
          .read(vaultListProvider.notifier)
          .setVisibility(artifact.slug, next);
    } catch (e) {
      _showError(e);
    }
  }

  void _viewSource() {
    showSourceSheet(context, slug: widget.artifact.slug);
  }

  void _share() {
    final artifact = widget.artifact;
    if (artifact.url.isEmpty) {
      _showError(const HyperVaultApiException(message: 'No link to share.'));
      return;
    }
    ShareService.shareText(artifact.url, subject: artifact.title);
  }

  void _connect() {
    final artifact = widget.artifact;
    showConnectSheet(
      context,
      artifactSlug: artifact.slug,
      artifactTitle: artifact.title,
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete artifact?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(vaultListProvider.notifier)
          .deleteArtifact(widget.artifact.slug);
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final artifact = widget.artifact;

    final connectionsAsync = ref.watch(connectionsListProvider);
    final identityCache = ref.watch(artifactIdentityCacheProvider);
    final userId = ref.watch(authProvider).user?.id;
    final connectionCount = connectionsAsync.maybeWhen(
      data: (connections) => connectionCountForSlug(
        cache: identityCache,
        userId: userId,
        connections: connections,
        slug: artifact.slug,
      ),
      orElse: () => null,
    );

    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      artifact.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: artifact.isPublic
                        ? 'Public artifact, tap to make private'
                        : 'Private artifact, tap to make public',
                    child: InkWell(
                      onTap: _toggleVisibility,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: HugeIcon(
                          icon: artifact.isPublic
                              ? HugeIcons.strokeRoundedGlobe02
                              : HugeIcons.strokeRoundedLockKey,
                          size: 18,
                          color: artifact.isPublic
                              ? Colors.green
                              : colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ShadBadge.secondary(child: Text(artifact.type)),
                  if (artifact.isJsx)
                    const ShadBadge(child: Text('React · auto-wrapped')),
                  if (artifact.isPwa)
                    ShadBadge.outline(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedRocket01,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text('Installable'),
                        ],
                      ),
                    ),
                  if (connectionCount != null && connectionCount > 0)
                    ShadBadge.outline(child: Text('🔗 $connectionCount')),
                ],
              ),
              if (artifact.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: artifact.tags
                      .map(
                        (tag) => Text(
                          '#$tag',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if ((artifact.sourcePrompt ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () =>
                      setState(() => _promptExpanded = !_promptExpanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '💬 Source prompt',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      HugeIcon(
                        icon: _promptExpanded
                            ? HugeIcons.strokeRoundedArrowUp01
                            : HugeIcons.strokeRoundedArrowDown01,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                if (_promptExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '"${artifact.sourcePrompt}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatRelativeTime(artifact.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedSourceCode,
                    tooltip: 'View source',
                    onTap: _viewSource,
                  ),
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedSquareArrowUpRight,
                    tooltip: 'Open',
                    onTap: widget.onTap,
                  ),
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedShare08,
                    tooltip: 'Share',
                    onTap: _share,
                  ),
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedLinkSquare01,
                    tooltip: 'Connect',
                    onTap: _connect,
                  ),
                  const Spacer(),
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    tooltip: 'Delete',
                    color: colorScheme.error,
                    onTap: _confirmDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: HugeIcon(icon: icon, size: 18, color: color),
        ),
      ),
    );
  }
}
