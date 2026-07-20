import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/enums.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../../on_device/views/model_manager_screen.dart';
import '../providers/hypervault_bridge_providers.dart';

/// Standalone power-user screen exercising one HyperVault context→on-device
/// generate→turns round trip (docs/mobile/prd/09-on-device-inference.md,
/// 10-byo-llm-backends.md). This is an opt-in demonstration of the bridge,
/// not part of the default on-device chat flow — see integration notes for
/// what wiring it into the live composer would additionally need.
class HyperVaultContextBridgeScreen extends ConsumerStatefulWidget {
  const HyperVaultContextBridgeScreen({super.key});

  @override
  ConsumerState<HyperVaultContextBridgeScreen> createState() =>
      _HyperVaultContextBridgeScreenState();
}

class _HyperVaultContextBridgeScreenState
    extends ConsumerState<HyperVaultContextBridgeScreen> {
  final _messageController = TextEditingController();
  bool _useRecall = true;
  bool _useSmartContext = false;
  bool _useDeepMemory = false;

  @override
  void initState() {
    super.initState();
    // Rebuilds the submit button's enabled state as the user types.
    _messageController.addListener(_onMessageChanged);
  }

  void _onMessageChanged() => setState(() {});

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engine = ref.watch(onDeviceEngineProvider);
    final run = ref.watch(hyperVaultBridgeRunProvider);
    final modelLoaded =
        engine.status == OnDeviceEngineStatus.loaded &&
        engine.loadedModelId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('On-device + HyperVault context')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Answers with your phone\'s on-device model, using the same '
                'wiki recall, smart-context, and deep-memory HyperVault '
                'assembles for server chat. The prompt is generated locally; '
                'only the turn you see below is saved to your vault.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              if (!modelLoaded)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No on-device model is loaded.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OnDeviceModelManagerScreen(),
                          ),
                        ),
                        child: const Text('Manage'),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCpu,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Running on ${engine.loadedModelId}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              ShadInputFormField(
                controller: _messageController,
                minLines: 2,
                maxLines: 5,
                label: const Text('Message'),
                placeholder: const Text('Ask something…'),
              ),
              const SizedBox(height: 12),
              ShadSwitch(
                value: _useRecall,
                onChanged: (v) => setState(() => _useRecall = v),
                label: const Text('Wiki recall'),
              ),
              const SizedBox(height: 8),
              ShadSwitch(
                value: _useSmartContext,
                onChanged: (v) => setState(() => _useSmartContext = v),
                label: const Text('Smart context compaction'),
              ),
              const SizedBox(height: 8),
              ShadSwitch(
                value: _useDeepMemory,
                onChanged: (v) => setState(() => _useDeepMemory = v),
                label: const Text('Deep memory (GraphRAG)'),
              ),
              const SizedBox(height: 20),
              ShadButton(
                width: double.infinity,
                enabled:
                    !run.running &&
                    modelLoaded &&
                    _messageController.text.trim().isNotEmpty,
                leading: run.running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const HugeIcon(icon: HugeIcons.strokeRoundedSent),
                onPressed: () {
                  final message = _messageController.text.trim();
                  if (message.isEmpty) return;
                  FocusScope.of(context).unfocus();
                  ref
                      .read(hyperVaultBridgeRunProvider.notifier)
                      .run(
                        message: message,
                        useRecall: _useRecall,
                        useSmartContext: _useSmartContext,
                        useDeepMemory: _useDeepMemory,
                      );
                },
                child: Text(run.running ? 'Running…' : 'Run round trip'),
              ),
              if (run.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    run.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
              if (run.result != null) ...[
                const SizedBox(height: 20),
                _ResultPanel(theme: theme),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends ConsumerWidget {
  final ThemeData theme;

  const _ResultPanel({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(hyperVaultBridgeRunProvider).result!;
    final chatContext = result.context;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reply', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(result.assistantText),
              const SizedBox(height: 10),
              Text(
                'Model: ${result.turn.model} · Conversation: '
                '${result.turn.conversationId}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        if (chatContext.recalled.isNotEmpty ||
            chatContext.recalledMemories.isNotEmpty ||
            chatContext.smartContext ||
            chatContext.deepMemory != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (chatContext.recalled.isNotEmpty)
                _InfoChip('${chatContext.recalled.length} artifacts recalled'),
              if (chatContext.recalledMemories.isNotEmpty)
                _InfoChip(
                  '${chatContext.recalledMemories.length} memories recalled',
                ),
              if (chatContext.smartContext)
                const _InfoChip('Smart context applied'),
              if (chatContext.deepMemory != null)
                _InfoChip(
                  '${chatContext.deepMemory!.length} deep-memory labels',
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
