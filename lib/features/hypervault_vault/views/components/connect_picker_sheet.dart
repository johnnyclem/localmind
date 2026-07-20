import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../data/models/hv_artifact.dart';
import '../../providers/hv_vault_providers.dart';

/// "Connect" picker (docs/mobile/prd/05-connections-sharing.md T-M5-01):
/// pick another artifact by title, or type a free-form slug/id/title (an
/// artifact this device hasn't listed, or a memory — the memory wiki itself
/// is a later epic, so it's a manual-entry fallback here).
Future<void> showConnectPickerSheet(
  BuildContext context, {
  required HvArtifact source,
}) {
  return showShadSheet(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (context) => ShadSheet(
      title: const Text('Connect'),
      description: Text('Link "${source.title}" to another item.'),
      child: _ConnectPickerBody(source: source),
    ),
  );
}

class _ConnectPickerBody extends ConsumerStatefulWidget {
  final HvArtifact source;
  const _ConnectPickerBody({required this.source});

  @override
  ConsumerState<_ConnectPickerBody> createState() => _ConnectPickerBodyState();
}

class _ConnectPickerBodyState extends ConsumerState<_ConnectPickerBody> {
  final _customController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _connectTo(String targetSlug) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(hvConnectionsProvider.notifier)
          .connect(
            sourceSlug: widget.source.slug,
            target: targetSlug,
            targetSlugIfArtifact: targetSlug,
          );
      if (mounted) {
        Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(content: Text(result.message)));
      }
    } on HvApiError catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(e.error)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artifacts = ref.watch(hvArtifactsProvider).value ?? const <HvArtifact>[];
    final candidates = artifacts.where((a) => a.slug != widget.source.slug).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (candidates.isNotEmpty) ...[
          Text('Artifacts', style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final a = candidates[index];
                return ListTile(
                  dense: true,
                  leading: const HugeIcon(icon: HugeIcons.strokeRoundedFile01, size: 18),
                  title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(a.slug),
                  onTap: _busy ? null : () => _connectTo(a.slug),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'Or type a slug, title, or id (artifact or memory)',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ShadInput(
                controller: _customController,
                placeholder: const Text('my-other-artifact'),
              ),
            ),
            const SizedBox(width: 8),
            ShadButton(
              enabled: !_busy,
              onPressed: () {
                final value = _customController.text.trim();
                if (value.isNotEmpty) _connectTo(value);
              },
              child: const Text('Connect'),
            ),
          ],
        ),
      ],
    );
  }
}
