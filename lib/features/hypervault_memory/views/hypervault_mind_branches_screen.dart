import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../data/models/hv_mind_branch.dart';
import '../providers/hypervault_memory_providers.dart';
import 'hypervault_mind_commits_screen.dart';
import 'hypervault_mind_merge_screen.dart';

/// Branch switcher + create/delete (T-M7-01 through T-M7-03). Checking out
/// a branch here sets [hyperVaultActiveBranchProvider] and pops back to the
/// Memory screen, which reloads against it.
class HypervaultMindBranchesScreen extends ConsumerStatefulWidget {
  const HypervaultMindBranchesScreen({super.key});

  @override
  ConsumerState<HypervaultMindBranchesScreen> createState() =>
      _HypervaultMindBranchesScreenState();
}

class _HypervaultMindBranchesScreenState
    extends ConsumerState<HypervaultMindBranchesScreen> {
  bool _creating = false;
  final _nameController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createBranch() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = ref.read(hyperVaultMindServiceProvider);
      final from = ref.read(hyperVaultActiveBranchProvider) ?? 'main';
      final branch = await service.createBranch(name: name, from: from);
      ref.invalidate(hyperVaultMindBranchesProvider);
      ref.read(hyperVaultActiveBranchProvider.notifier).checkout(branch.name);
      ref.invalidate(hyperVaultMemoryBrowseProvider);
      if (mounted) {
        setState(() {
          _creating = false;
          _nameController.clear();
        });
      }
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not create branch: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteBranch(HvMindBranch branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Really delete?'),
        content: Text('Branch "${branch.name}" and its commits will be gone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = ref.read(hyperVaultMindServiceProvider);
      await service.deleteBranch(branch.name);
      if (ref.read(hyperVaultActiveBranchProvider) == branch.name) {
        ref.read(hyperVaultActiveBranchProvider.notifier).checkout(null);
        ref.invalidate(hyperVaultMemoryBrowseProvider);
      }
      ref.invalidate(hyperVaultMindBranchesProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Branch "${branch.name}" is gone.')),
      );
    } on HvApiError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete branch: $e')),
      );
    }
  }

  void _checkout(HvMindBranch branch) {
    ref
        .read(hyperVaultActiveBranchProvider.notifier)
        .checkout(branch.isDefault ? null : branch.name);
    ref.invalidate(hyperVaultMemoryBrowseProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branchesAsync = ref.watch(hyperVaultMindBranchesProvider);
    final active = ref.watch(hyperVaultActiveBranchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches'),
        actions: [
          IconButton(
            tooltip: 'New branch',
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlusSign),
            onPressed: () => setState(() => _creating = !_creating),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_creating)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ShadInputFormField(
                        controller: _nameController,
                        placeholder: const Text('branch-name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShadButton(
                      enabled: !_busy,
                      onPressed: _createBranch,
                      child: const Text('Fork'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: branchesAsync.when(
                data: (branches) => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: branches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final branch = branches[i];
                    final isActive = branch.isDefault
                        ? active == null
                        : active == branch.name;
                    return ShadCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _checkout(branch),
                              child: Row(
                                children: [
                                  HugeIcon(
                                    icon: isActive
                                        ? HugeIcons
                                              .strokeRoundedCheckmarkCircle02
                                        : HugeIcons.strokeRoundedGitBranch,
                                    size: 18,
                                    color: isActive ? Colors.green : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          branch.isDefault
                                              ? '${branch.name} (default)'
                                              : branch.name,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        Text(
                                          '${branch.memoryCount} ${branch.memoryCount == 1 ? 'memory' : 'memories'}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Commits',
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedGitCommit,
                              size: 18,
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HypervaultMindCommitsScreen(
                                  branch: branch.isDefault ? null : branch.name,
                                  branchLabel: branch.name,
                                ),
                              ),
                            ),
                          ),
                          if (!branch.isDefault) ...[
                            IconButton(
                              tooltip: 'Merge into main',
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedGitMerge,
                                size: 18,
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => HypervaultMindMergeScreen(
                                    source: branch.name,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedDelete02,
                                size: 18,
                              ),
                              onPressed: () => _deleteBranch(branch),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      err is HvApiError
                          ? err.error
                          : 'Could not load branches: $err',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
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
