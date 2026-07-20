import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../../hypervault/providers/hypervault_providers.dart';
import '../data/models/hv_backend.dart';
import '../providers/hypervault_backends_providers.dart';
import 'components/hypervault_backend_card.dart';
import 'hypervault_backend_form_screen.dart';

/// Connected LLM backends list/manage screen (docs/mobile/prd/
/// 10-byo-llm-backends.md T-M10-01/06/07). These are the same `/api/backends`
/// rows the existing model picker (`HyperVaultChatService`) already chats
/// through — this screen just adds connect/edit/disconnect from the phone.
class HyperVaultBackendsScreen extends ConsumerWidget {
  const HyperVaultBackendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshot = ref.watch(hyperVaultBackendsProvider);
    final maxBackends =
        ref.watch(hyperVaultCapabilitiesProvider).value?.limits.maxBackends ??
        20;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Backends'),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
            onPressed: () =>
                ref.read(hyperVaultBackendsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: snapshot.when(
          data: (snap) => _BackendsBody(
            snapshot: snap,
            maxBackends: maxBackends,
            theme: theme,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: e is HvApiError
                ? e.error
                : 'Could not load your connected backends.',
            onRetry: () => ref.invalidate(hyperVaultBackendsProvider),
          ),
        ),
      ),
      floatingActionButton: snapshot.maybeWhen(
        data: (snap) => snap.backends.length >= maxBackends
            ? null
            : FloatingActionButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        HyperVaultBackendFormScreen(providers: snap.providers),
                  ),
                ),
                child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _BackendsBody extends StatelessWidget {
  final HvBackendsSnapshot snapshot;
  final int maxBackends;
  final ThemeData theme;

  const _BackendsBody({
    required this.snapshot,
    required this.maxBackends,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.backends.isEmpty) {
      return _EmptyState(providers: snapshot.providers);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            '${snapshot.backends.length} of $maxBackends connected',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: snapshot.backends.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final backend = snapshot.backends[index];
              return HyperVaultBackendCard(
                backend: backend,
                spec: snapshot.specFor(backend.provider),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HyperVaultBackendFormScreen(
                      providers: snapshot.providers,
                      editing: backend,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final List<HvProviderSpec> providers;

  const _EmptyState({required this.providers});

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
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 20),
            Text('No backends connected', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Connect OpenAI, Anthropic, xAI, Gemini, Mistral, a local '
              'Ollama/LM Studio runtime, or a custom endpoint to chat '
              'through it from HyperVault.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ShadButton(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      HyperVaultBackendFormScreen(providers: providers),
                ),
              ),
              child: const Text('Connect a backend'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ShadButton.outline(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
