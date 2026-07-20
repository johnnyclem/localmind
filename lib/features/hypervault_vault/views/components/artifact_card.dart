import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/hv_vault_format.dart';
import '../../data/models/hv_artifact.dart';

/// One artifact row on the vault list (docs/mobile/prd/03-vault-artifacts.md
/// T-M3-02): title, type chip (opens view-source), badges, relative date,
/// tag chips, a collapsible source-prompt disclosure, and a quick action row.
class ArtifactCard extends StatefulWidget {
  final HvArtifact artifact;
  final int? connectionCount;
  final VoidCallback onTap;
  final VoidCallback onViewSource;
  final VoidCallback onToggleVisibility;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onConnect;
  final VoidCallback onDelete;

  const ArtifactCard({
    super.key,
    required this.artifact,
    this.connectionCount,
    required this.onTap,
    required this.onViewSource,
    required this.onToggleVisibility,
    required this.onOpen,
    required this.onShare,
    required this.onConnect,
    required this.onDelete,
  });

  @override
  State<ArtifactCard> createState() => _ArtifactCardState();
}

class _ArtifactCardState extends State<ArtifactCard> {
  bool _promptExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artifact = widget.artifact;
    final typeColor = hvArtifactTypeColor(artifact.type, isJsx: artifact.isJsx);

    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      artifact.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: artifact.isPrivate ? 'Private artifact' : 'Public artifact',
                    child: InkWell(
                      onTap: widget.onToggleVisibility,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: HugeIcon(
                          icon: artifact.isPrivate
                              ? HugeIcons.strokeRoundedLockKey
                              : HugeIcons.strokeRoundedGlobe02,
                          size: 18,
                          color: artifact.isPrivate
                              ? theme.colorScheme.outline
                              : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: widget.onViewSource,
                    borderRadius: BorderRadius.circular(6),
                    child: ShadBadge(
                      backgroundColor: typeColor.withValues(alpha: 0.15),
                      foregroundColor: typeColor,
                      child: Text(artifact.type),
                    ),
                  ),
                  if (artifact.isJsx)
                    const ShadBadge.secondary(child: Text('React · auto-wrapped')),
                  if (artifact.isPwa)
                    const ShadBadge.outline(child: Text('Installable')),
                  if (widget.connectionCount != null && widget.connectionCount! > 0)
                    ShadBadge.outline(
                      child: Text('🔗 ${widget.connectionCount}'),
                    ),
                  Text(
                    hvRelativeTime(artifact.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              if (artifact.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: artifact.tags
                      .map(
                        (t) => Text(
                          '#$t',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if ((artifact.sourcePrompt ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => setState(() => _promptExpanded = !_promptExpanded),
                  child: Row(
                    children: [
                      Text(
                        '💬 Source prompt',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      HugeIcon(
                        icon: _promptExpanded
                            ? HugeIcons.strokeRoundedArrowUp01
                            : HugeIcons.strokeRoundedArrowDown01,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                if (_promptExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '“${artifact.sourcePrompt}”',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedSquareArrowUpRight,
                    tooltip: 'Open',
                    onTap: widget.onOpen,
                  ),
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedShare08,
                    tooltip: 'Share / copy link',
                    onTap: widget.onShare,
                  ),
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedLinkSquare01,
                    tooltip: 'Connect',
                    onTap: widget.onConnect,
                  ),
                  const Spacer(),
                  _ActionIcon(
                    icon: HugeIcons.strokeRoundedDelete01,
                    tooltip: 'Delete',
                    color: theme.colorScheme.error,
                    onTap: widget.onDelete,
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
