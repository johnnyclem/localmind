import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../data/models/hv_mind_merge.dart';
import '../providers/hypervault_memory_providers.dart';

/// Merge dialog (T-M7-04). Clean merges show the change tally and check out
/// `main`. A 409 conflict only has a message to show here — the shared
/// [HyperVaultApiClient] normalizes error bodies to `{status, error}`, so
/// the per-conflict `ours`/`theirs` picker (T-M7-05) isn't reachable from
/// this client without extending it (see [HvMergeOutcome] doc comment and
/// this feature's integration notes).
class HypervaultMindMergeScreen extends ConsumerStatefulWidget {
  final String source;
  final String target;

  const HypervaultMindMergeScreen({
    super.key,
    required this.source,
    this.target = 'main',
  });

  @override
  ConsumerState<HypervaultMindMergeScreen> createState() =>
      _HypervaultMindMergeScreenState();
}

class _HypervaultMindMergeScreenState
    extends ConsumerState<HypervaultMindMergeScreen> {
  bool _merging = false;
  HvMergeOutcome? _result;
  String? _error;
  bool _conflict = false;

  Future<void> _merge() async {
    setState(() {
      _merging = true;
      _error = null;
      _conflict = false;
    });
    try {
      final service = ref.read(hyperVaultMindServiceProvider);
      final outcome = await service.merge(
        source: widget.source,
        target: widget.target,
      );
      if (!mounted) return;
      setState(() => _result = outcome);
      if (outcome.commitId != null) {
        ref.read(hyperVaultActiveBranchProvider.notifier).checkout(null);
        ref.invalidate(hyperVaultMemoryBrowseProvider);
        ref.invalidate(hyperVaultMindBranchesProvider);
      }
    } on HvApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.error;
        _conflict = e.status == 409;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Merge failed: $e');
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Merge')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Merge "${widget.source}" into "${widget.target}". Memories only '
                'one side touched merge in automatically; links merge set-wise.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ShadButton(
                enabled: !_merging,
                leading: _merging
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const HugeIcon(
                        icon: HugeIcons.strokeRoundedGitMerge,
                        size: 16,
                      ),
                onPressed: _merge,
                child: Text('Merge ${widget.source} into ${widget.target}'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 20),
                ShadCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_result!.message, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Created ${_result!.merged.created} · Updated ${_result!.merged.updated} · '
                        'Deleted ${_result!.merged.deleted} · Links changed ${_result!.linksChanged}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                if (_conflict) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Per-conflict ours/theirs resolution isn\'t available in this '
                    'app yet — resolve the conflict from the web app, then merge '
                    'again here.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
