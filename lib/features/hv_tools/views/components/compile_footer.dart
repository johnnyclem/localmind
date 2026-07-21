import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../providers/hv_tools_providers.dart';
import 'compile_result_card.dart';

/// Sticky footer with Compile Tools / Undo. Compile can take up to 300s
/// server-side (live tool re-resolution + embedding), so this shows a
/// determinate-looking progress bar rather than a spinner that could read as
/// hung, per the PRD.
class CompileFooter extends ConsumerWidget {
  const CompileFooter({super.key});

  Future<void> _compile(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(hvToolsProvider.notifier).compile();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toolkit compiled. New chats now use it.'),
          ),
        );
      }
    } catch (e) {
      // Also surfaced inline via state.compileError; toast for visibility.
      final message = e is HyperVaultApiException
          ? e.message
          : 'Compile failed.';
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(hvToolsProvider).value;
    if (state == null) return const SizedBox.shrink();

    final dirty = state.isDirty;
    final pending = state.pendingChangeCount;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.compileError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    state.compileError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              if (state.lastCompileResult != null && !dirty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CompileResultCard(result: state.lastCompileResult!),
                ),
              if (state.compiling)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(),
                ),
              Row(
                children: [
                  if (dirty)
                    Expanded(
                      child: Text(
                        '$pending pending change${pending == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  ShadButton.outline(
                    onPressed: (!dirty || state.compiling)
                        ? null
                        : () => ref.read(hvToolsProvider.notifier).undo(),
                    child: const Text('Undo'),
                  ),
                  const SizedBox(width: 8),
                  ShadButton(
                    onPressed: (!dirty || state.compiling)
                        ? null
                        : () => _compile(context, ref),
                    child: Text(
                      state.compiling ? 'Compiling…' : 'Compile Tools',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
