import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../providers/hv_vault_providers.dart';

/// Bottom sheet showing an artifact's raw stored markup, read-only and
/// selectable, with a copy button — `GET /api/artifacts/[slug]/source`.
Future<void> showViewSourceSheet(BuildContext context, String slug) {
  return showShadSheet(
    context: context,
    side: ShadSheetSide.bottom,
    builder: (context) => ShadSheet(
      constraints: const BoxConstraints(maxHeight: 560),
      child: SizedBox(
        height: 480,
        child: _ViewSourceBody(slug: slug),
      ),
    ),
  );
}

class _ViewSourceBody extends ConsumerStatefulWidget {
  final String slug;
  const _ViewSourceBody({required this.slug});

  @override
  ConsumerState<_ViewSourceBody> createState() => _ViewSourceBodyState();
}

class _ViewSourceBodyState extends ConsumerState<_ViewSourceBody> {
  late Future<String> _future;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(hvVaultServiceProvider).viewSource(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Source · ${widget.slug}', style: theme.textTheme.titleSmall),
            ),
            FutureBuilder<String>(
              future: _future,
              builder: (context, snapshot) {
                final content = snapshot.data;
                return ShadButton.ghost(
                  enabled: content != null,
                  leading: HugeIcon(
                    icon: _copied
                        ? HugeIcons.strokeRoundedCheckmarkCircle01
                        : HugeIcons.strokeRoundedCopy01,
                    size: 16,
                  ),
                  onPressed: content == null
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: content));
                          setState(() => _copied = true);
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            if (mounted) setState(() => _copied = false);
                          });
                        },
                  child: Text(_copied ? 'Copied!' : 'Copy'),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<String>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final e = snapshot.error;
                return Center(
                  child: Text(
                    e is HvApiError ? e.error : 'Could not load source.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    snapshot.data ?? '',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
