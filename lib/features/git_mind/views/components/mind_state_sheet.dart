import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../data/models/git_mind_models.dart';
import '../../providers/git_mind_providers.dart';

/// Time-travel sheet (T-M7-09, stretch) — a read-only snapshot of the wiki
/// `at` a given commit, branch name, or ISO timestamp
/// (`GET /api/mind/state?at=&branch=`). Reached from a commit-log row's
/// "View as of this commit" action; no write actions live here.
Future<void> showMindStateSheet(
  BuildContext context, {
  required String at,
  required String branch,
  String? label,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _MindStateSheet(at: at, branch: branch, label: label),
  );
}

class _MindStateSheet extends ConsumerStatefulWidget {
  final String at;
  final String branch;
  final String? label;

  const _MindStateSheet({required this.at, required this.branch, this.label});

  @override
  ConsumerState<_MindStateSheet> createState() => _MindStateSheetState();
}

class _MindStateSheetState extends ConsumerState<_MindStateSheet> {
  late Future<MindStateSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<MindStateSnapshot> _fetch() => ref
      .read(gitMindApiServiceProvider)
      .fetchState(at: widget.at, branch: widget.branch);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedTime04, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Viewing as of ${widget.label ?? widget.at}',
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ShadBadge.outline(
                child: Text('read-only snapshot · ${widget.branch}'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<MindStateSnapshot>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      final err = snapshot.error;
                      return Center(
                        child: Text(
                          err is HyperVaultApiException
                              ? err.message
                              : 'Could not load that snapshot.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final state = snapshot.data!;
                    if (state.memories.isEmpty) {
                      return const Center(
                        child: Text('No memories existed at this point.'),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: state.memories.length,
                      itemBuilder: (context, index) {
                        final memory = state.memories[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ShadCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  memory.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (memory.summary.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    memory.summary,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (memory.tags.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: memory.tags
                                        .map((t) => Text(
                                              '#$t',
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: theme.colorScheme.primary,
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
