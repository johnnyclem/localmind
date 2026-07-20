import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../data/models/hv_artifact.dart';
import '../data/models/hv_connection.dart';
import '../providers/hv_vault_providers.dart';
import 'artifact_detail_screen.dart';
import 'components/artifact_card.dart';
import 'components/connect_picker_sheet.dart';
import 'components/view_source_sheet.dart';
import 'components/vault_graph_view.dart';
import 'new_from_chat_screen.dart';

/// The vault tab: artifact list ⇆ graph toggle, "New from chat" entry point.
/// Wire this at whatever route the integration pass picks for the vault tab
/// (see the structured report's integrationNotes).
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

enum _VaultView { list, graph }

class _VaultScreenState extends ConsumerState<VaultScreen> {
  _VaultView _view = _VaultView.list;

  Future<void> _openNewFromChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewFromChatScreen()),
    );
  }

  void _openDetail(HvArtifact artifact) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArtifactDetailScreen(artifact: artifact)),
    );
  }

  Future<void> _pullToRefresh() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Future.wait([
        ref.read(hvArtifactsProvider.notifier).refresh(),
        ref.read(hvConnectionsProvider.notifier).refresh(),
      ]);
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not refresh: $e')));
    }
  }

  Future<void> _toggleVisibility(HvArtifact artifact) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(hvArtifactsProvider.notifier)
          .setVisibility(artifact.slug, artifact.isPrivate ? 'public' : 'private');
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    }
  }

  Future<void> _delete(HvArtifact artifact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete artifact?'),
        content: Text('“${artifact.title}” will be gone for good.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(hvArtifactsProvider.notifier).removeArtifact(artifact.slug);
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    }
  }

  Future<void> _open(HvArtifact artifact) async {
    final uri = Uri.tryParse(artifact.url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _share(HvArtifact artifact) async {
    await SharePlus.instance.share(
      ShareParams(text: artifact.url, subject: artifact.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artifactsAsync = ref.watch(hvArtifactsProvider);
    final connectionsAsync = ref.watch(hvConnectionsProvider);
    final userId = ref.watch(hvVaultUserIdProvider);
    final cache = ref.watch(hvVaultCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ShadButton(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 16),
              onPressed: _openNewFromChat,
              child: const Text('New from chat'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: artifactsAsync.when(
                      data: (items) => Text(
                        '${items.length} artifact${items.length == 1 ? '' : 's'} on your flight deck',
                        style: theme.textTheme.labelMedium,
                      ),
                      loading: () => Text('Loading…', style: theme.textTheme.labelMedium),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                  _ViewToggle(
                    value: _view,
                    onChanged: (v) => setState(() => _view = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: artifactsAsync.when(
                data: (items) {
                  if (items.isEmpty) return _EmptyState(onCreate: _openNewFromChat);
                  if (_view == _VaultView.graph) {
                    return VaultGraphView(
                      artifacts: items,
                      connections: connectionsAsync.value ?? const HvConnectionsData(),
                      idForSlug: (slug) =>
                          userId == null ? null : cache.idForSlug(userId, slug),
                      onTapArtifact: (slug) {
                        final artifact = items.where((a) => a.slug == slug).firstOrNull;
                        if (artifact != null) _openDetail(artifact);
                      },
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _pullToRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final artifact = items[index];
                        final count = userId == null
                            ? null
                            : hvConnectionCountForSlug(
                                cache,
                                connectionsAsync.value ?? const HvConnectionsData(),
                                userId,
                                artifact.slug,
                              );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ArtifactCard(
                            artifact: artifact,
                            connectionCount: count,
                            onTap: () => _openDetail(artifact),
                            onViewSource: () => showViewSourceSheet(context, artifact.slug),
                            onToggleVisibility: () => _toggleVisibility(artifact),
                            onOpen: () => _open(artifact),
                            onShare: () => _share(artifact),
                            onConnect: () => showConnectPickerSheet(context, source: artifact),
                            onDelete: () => _delete(artifact),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          color: theme.colorScheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          err is HvApiError ? err.error : 'Could not load your vault.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ShadButton.outline(
                          onPressed: () => ref.invalidate(hvArtifactsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final _VaultView value;
  final ValueChanged<_VaultView> onChanged;

  const _ViewToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget segment(_VaultView v, String label) {
      final selected = v == value;
      return InkWell(
        onTap: () => onChanged(v),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(_VaultView.list, 'List'),
          segment(_VaultView.graph, 'Graph'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCloudServer,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 20),
            Text('Your flight deck is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Save something your AI made and it will show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 20),
            ShadButton(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 16),
              onPressed: onCreate,
              child: const Text('Save your first artifact'),
            ),
          ],
        ),
      ),
    );
  }
}
