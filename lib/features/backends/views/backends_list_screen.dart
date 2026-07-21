import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/system_insets.dart';
import '../data/models/backend.dart';
import '../providers/backends_providers.dart';
import 'components/backend_card.dart';

class BackendsListScreen extends ConsumerWidget {
  const BackendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backendsAsync = ref.watch(backendsProvider);
    final systemBottomInset = bottomSystemInset(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: topPadding + 8,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0A0A0A)
                    : const Color(0xFFFAFAFA),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFE5E5E5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedMenu01),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Backends',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: backendsAsync.when(
                data: (result) => result.backends.isEmpty
                    ? _buildEmptyState(context, theme)
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(backendsProvider.notifier).refresh(),
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            16 + systemBottomInset + 80,
                          ),
                          itemCount: result.backends.length,
                          itemBuilder: (context, index) {
                            final backend = result.backends[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: BackendCard(
                                backend: backend,
                                onTap: () => context.push(
                                  AppRoutes.addBackend,
                                  extra: backend,
                                ),
                                onDelete: () =>
                                    _confirmDelete(context, ref, backend),
                              ),
                            );
                          },
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          color: theme.colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          err is HyperVaultApiException
                              ? err.message
                              : 'Something went wrong loading your backends.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.invalidate(backendsProvider),
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
        PositionedDirectional(
          bottom: 24,
          end: 24,
          child: FloatingActionButton(
            onPressed: () => context.push(AppRoutes.addBackend),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCloudServer,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No backends connected yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'No backends connected yet — add one to chat with OpenAI, '
              'Anthropic, Ollama, or any OpenAI-compatible endpoint.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.addBackend),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
              label: const Text('Add backend'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Backend backend) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove backend?'),
          content: Text(
            'This disconnects "${backend.name.isNotEmpty ? backend.name : backend.provider}". '
            'Any chats using it will fall back to another available backend.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final message = await ref
                      .read(backendsProvider.notifier)
                      .deleteBackend(backend.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                } on HyperVaultApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
