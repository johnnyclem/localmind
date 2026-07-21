import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/hv_error_toast.dart';
import '../data/models/artifact.dart';
import '../providers/vault_providers.dart';
import 'components/artifact_card.dart';

/// Vault — Artifacts list (mobile PRD T-M3-01). Pull-to-refresh, cached
/// cold start via [vaultListProvider], FAB into the save flow.
class VaultListScreen extends ConsumerWidget {
  const VaultListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultListProvider);

    ref.listen<AsyncValue<List<Artifact>>>(vaultListProvider, (previous, next) {
      next.whenOrNull(error: (err, _) => showHvError(context, err));
    });

    return Scaffold(
      appBar: AppBar(
        title: vaultAsync.when(
          data: (items) => Text(
            items.isEmpty
                ? 'Vault'
                : '${items.length} artifact${items.length == 1 ? '' : 's'} on your flight deck',
          ),
          loading: () => const Text('Vault'),
          error: (_, _) => const Text('Vault'),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedUserGroup),
            tooltip: 'Shared with you',
            onPressed: () => context.push(AppRoutes.sharedWithMe),
          ),
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedChartBubble01),
            tooltip: 'Graph view',
            onPressed: () => context.push(AppRoutes.vaultGraph),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.saveArtifact),
        tooltip: 'Save artifact',
        child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
      ),
      body: vaultAsync.when(
        data: (items) => items.isEmpty
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: () => ref.read(vaultListProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final artifact = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ArtifactCard(
                        artifact: artifact,
                        onTap: () => context.push(
                          AppRoutes.artifactDetail,
                          extra: artifact.slug,
                        ),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(context, ref, err),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedPackageOpen,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Your flight deck is empty',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Save something your AI made and it will show up here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.saveArtifact),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
              label: const Text('Save your first artifact'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    final message = err is HyperVaultApiException
        ? err.message
        : err.toString();
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(vaultListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
