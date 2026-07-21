import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../data/models/share.dart';
import '../providers/connections_providers.dart';

/// "Shared with you" screen (mobile PRD M5, T-M5-05/06) for
/// [AppRoutes.sharedWithMe]. No REST list endpoint exists for inbound
/// shares — this reads `artifact_shares` directly from Supabase under RLS
/// (`shared_with_id = auth.uid()`), joined to the artifact and owner
/// profile. The exact join/column names are a best-effort match of
/// hypervault-web's schema; any failure (missing table/column, unexpected
/// shape, RLS mismatch) degrades to a friendly error state rather than
/// crashing, per the epic's documented backend gap.
class SharedWithMeScreen extends ConsumerStatefulWidget {
  const SharedWithMeScreen({super.key});

  @override
  ConsumerState<SharedWithMeScreen> createState() => _SharedWithMeScreenState();
}

class _SharedWithMeScreenState extends ConsumerState<SharedWithMeScreen> {
  bool _loading = true;
  String? _error;
  List<InboundShare> _items = const [];
  final Set<String> _leavingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = sb.Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }
      final rows = await client
          .from('artifact_shares')
          .select(
            'id, created_at, artifacts(slug, title, type), '
            'owner:profiles!artifact_shares_owner_id_fkey(display_name, email)',
          )
          .eq('shared_with_id', userId)
          .order('created_at', ascending: false);

      final items = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(InboundShare.fromRow)
          .toList();

      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              "Couldn't load shared artifacts right now. Pull to refresh to try again.";
          _loading = false;
        });
      }
    }
  }

  Future<void> _leave(InboundShare share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave shared artifact?'),
        content: Text(
          'You will lose access to "${share.artifactTitle}" unless '
          '${share.ownerName} shares it with you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _leavingIds.add(share.shareId));
    final previous = _items;
    setState(() {
      _items = _items.where((s) => s.shareId != share.shareId).toList();
    });
    try {
      await ref.read(sharesApiServiceProvider).revoke(share.shareId);
    } on HyperVaultApiException catch (e) {
      if (mounted) {
        setState(() => _items = previous);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _items = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not leave that artifact.')),
        );
      }
    } finally {
      if (mounted) setState(() => _leavingIds.remove(share.shareId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared with you')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState(context)
          : _items.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final share = _items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SharedArtifactCard(
                      share: share,
                      leaving: _leavingIds.contains(share.shareId),
                      onOpen: share.artifactSlug == null
                          ? null
                          : () => context.push(
                              AppRoutes.artifactDetail,
                              extra: share.artifactSlug,
                            ),
                      onLeave: () => _leave(share),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 64),
          HugeIcon(
            icon: HugeIcons.strokeRoundedShare08,
            size: 72,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing shared with you yet',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Artifacts other people invite you to will show up here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SharedArtifactCard extends StatelessWidget {
  final InboundShare share;
  final bool leaving;
  final VoidCallback? onOpen;
  final VoidCallback onLeave;

  const _SharedArtifactCard({
    required this.share,
    required this.leaving,
    required this.onOpen,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  share.artifactTitle,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ShadBadge.secondary(child: Text(share.artifactType)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Shared by ${share.ownerName} · ${_formatDate(share.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: leaving ? null : onLeave,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedLogout01,
                  size: 16,
                  color: Colors.red,
                ),
                label: const Text('Leave', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 8),
              ShadButton(
                onPressed: leaving || onOpen == null ? null : onOpen,
                child: const Text('Open'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
