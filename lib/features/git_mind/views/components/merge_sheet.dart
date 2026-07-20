import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../data/git_mind_api_service.dart';
import '../../data/models/git_mind_models.dart';
import '../../providers/git_mind_providers.dart';

/// Merge sheet (T-M7-04/05): pick a source branch to merge into [targetBranch],
/// optional commit message, submit. On a clean merge it pops with the
/// [MergeResult] so the caller can toast the summary. On a 409 it switches
/// in-place to a per-memory ours/theirs conflict picker and resubmits with
/// `resolutions` — a further 409 just re-renders the still-unresolved
/// conflicts rather than closing the sheet.
Future<MergeResult?> showMergeSheet(
  BuildContext context, {
  required String targetBranch,
  required List<MindBranch> branches,
}) {
  return showModalBottomSheet<MergeResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _MergeSheet(targetBranch: targetBranch, branches: branches),
  );
}

class _MergeSheet extends ConsumerStatefulWidget {
  final String targetBranch;
  final List<MindBranch> branches;

  const _MergeSheet({required this.targetBranch, required this.branches});

  @override
  ConsumerState<_MergeSheet> createState() => _MergeSheetState();
}

class _MergeSheetState extends ConsumerState<_MergeSheet> {
  final _messageController = TextEditingController();
  late String? _source;

  bool _submitting = false;
  String? _error;
  List<MergeConflict>? _conflicts;
  final Map<String, MergeChoice> _resolutions = {};

  @override
  void initState() {
    super.initState();
    final candidates = widget.branches
        .where((b) => b.name != widget.targetBranch)
        .toList();
    _source = candidates.isNotEmpty ? candidates.first.name : null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final source = _source;
    if (source == null || source.trim().isEmpty) {
      setState(() => _error = 'Pick a branch to merge in.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(gitMindApiServiceProvider)
          .merge(
            source: source,
            target: widget.targetBranch,
            message: _messageController.text,
          );
      if (mounted) Navigator.of(context).pop(result);
    } on MergeConflictException catch (e) {
      setState(() {
        _submitting = false;
        _error = null;
        _conflicts = e.conflicts;
        _resolutions.clear();
      });
    } on HyperVaultApiException catch (e) {
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _submitting = false;
        _error = 'Could not merge — check your connection and try again.';
      });
    }
  }

  Future<void> _resolveAndMerge() async {
    final conflicts = _conflicts;
    final source = _source;
    if (conflicts == null || source == null) return;
    if (_resolutions.length < conflicts.length) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(gitMindApiServiceProvider)
          .merge(
            source: source,
            target: widget.targetBranch,
            message: _messageController.text,
            resolutions: conflicts
                .map(
                  (c) => MergeResolution(
                    memoryId: c.memoryId,
                    choice: _resolutions[c.memoryId]!,
                  ),
                )
                .toList(),
          );
      if (mounted) Navigator.of(context).pop(result);
    } on MergeConflictException catch (e) {
      // Some conflicts remain (or new ones appeared) — re-render them.
      setState(() {
        _submitting = false;
        _conflicts = e.conflicts;
        _resolutions.removeWhere(
          (memoryId, _) => !e.conflicts.any((c) => c.memoryId == memoryId),
        );
      });
    } on HyperVaultApiException catch (e) {
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _submitting = false;
        _error = 'Could not merge — check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflicts = _conflicts;

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
                HugeIcon(icon: HugeIcons.strokeRoundedGitMerge, size: 20),
                const SizedBox(width: 8),
                Text(
                  conflicts == null ? 'Merge branch' : 'Resolve conflicts',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (conflicts == null)
              ..._buildMergeForm(theme)
            else
              ..._buildConflictList(theme, conflicts),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: _submitting
                    ? null
                    : (conflicts == null ? _submit : _resolveAndMerge),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        conflicts == null
                            ? 'Merge into ${widget.targetBranch}'
                            : 'Resolve & merge',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMergeForm(ThemeData theme) {
    return [
      Text(
        'Merging into "${widget.targetBranch}"',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _source,
        decoration: const InputDecoration(labelText: 'Merge from branch'),
        items: widget.branches
            .where((b) => b.name != widget.targetBranch)
            .map(
              (b) => DropdownMenuItem(value: b.name, child: Text(b.name)),
            )
            .toList(),
        onChanged: (value) => setState(() => _source = value),
      ),
      const SizedBox(height: 12),
      ShadInput(
        controller: _messageController,
        placeholder: const Text('Merge message (optional)'),
      ),
    ];
  }

  List<Widget> _buildConflictList(
    ThemeData theme,
    List<MergeConflict> conflicts,
  ) {
    return [
      Text(
        '${conflicts.length} ${conflicts.length == 1 ? 'memory' : 'memories'} '
        'changed on both sides — pick which version to keep for each.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      const SizedBox(height: 12),
      ...conflicts.map((conflict) => _ConflictCard(
            conflict: conflict,
            selected: _resolutions[conflict.memoryId],
            onSelected: (choice) => setState(
              () => _resolutions[conflict.memoryId] = choice,
            ),
          )),
    ];
  }
}

class _ConflictCard extends StatelessWidget {
  final MergeConflict conflict;
  final MergeChoice? selected;
  final ValueChanged<MergeChoice> onSelected;

  const _ConflictCard({
    required this.conflict,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conflict.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SidePreview(
                    label: 'Ours',
                    title: conflict.oursTitle,
                    content: conflict.oursContent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SidePreview(
                    label: 'Theirs',
                    title: conflict.theirsTitle,
                    content: conflict.theirsContent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Keep ours'),
                  selected: selected == MergeChoice.ours,
                  onSelected: (_) => onSelected(MergeChoice.ours),
                ),
                ChoiceChip(
                  label: const Text('Keep theirs'),
                  selected: selected == MergeChoice.theirs,
                  onSelected: (_) => onSelected(MergeChoice.theirs),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidePreview extends StatelessWidget {
  final String label;
  final String? title;
  final String? content;

  const _SidePreview({required this.label, this.title, this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeleted = title == null && content == null;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          if (isDeleted)
            Text(
              'deleted here',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.error,
              ),
            )
          else ...[
            Text(
              title ?? 'Untitled',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (content != null && content!.isNotEmpty)
              Text(
                content!,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ],
      ),
    );
  }
}
