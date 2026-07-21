import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../data/models/git_mind_models.dart';
import '../../providers/git_mind_providers.dart';

/// Create-branch sheet (T-M7-02): name + optional `from` (defaults to the
/// branch currently checked out on the Git-mind screen). Pops with the new
/// branch's [CreateBranchResult] on success so the caller can check it out
/// and refresh the branch list.
Future<CreateBranchResult?> showCreateBranchSheet(
  BuildContext context, {
  required String fromBranch,
}) {
  return showModalBottomSheet<CreateBranchResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CreateBranchSheet(fromBranch: fromBranch),
  );
}

class _CreateBranchSheet extends ConsumerStatefulWidget {
  final String fromBranch;

  const _CreateBranchSheet({required this.fromBranch});

  @override
  ConsumerState<_CreateBranchSheet> createState() => _CreateBranchSheetState();
}

class _CreateBranchSheetState extends ConsumerState<_CreateBranchSheet> {
  final _nameController = TextEditingController();
  late final TextEditingController _fromController;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.fromBranch);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fromController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the branch a name.');
      return;
    }
    final from = _fromController.text.trim().isEmpty
        ? 'main'
        : _fromController.text.trim();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(gitMindApiServiceProvider)
          .createBranch(name: name, from: from);
      unawaited(ref.read(mindBranchesProvider.notifier).refresh());
      if (mounted) Navigator.of(context).pop(result);
    } on HyperVaultApiException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not create that branch — check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedGitBranch, size: 20),
                const SizedBox(width: 8),
                Text('New branch', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ShadInput(
              controller: _nameController,
              placeholder: const Text('Branch name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: _fromController,
              placeholder: const Text('From branch'),
            ),
            const SizedBox(height: 4),
            Text(
              'Forks a new branch from "${widget.fromBranch}" unless you change it above.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create branch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {}
