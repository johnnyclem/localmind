import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../providers/vault_providers.dart';

/// Bottom sheet showing an artifact's raw source (`GET /api/artifacts/
/// [slug]/source`), copyable via the app bar-style action. Shared between
/// the artifact detail screen and the vault list's inline "view source"
/// card action so there is a single source-viewing implementation.
void showSourceSheet(BuildContext context, {required String slug}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SourceSheet(slug: slug),
  );
}

class _SourceSheet extends ConsumerStatefulWidget {
  final String slug;

  const _SourceSheet({required this.slug});

  @override
  ConsumerState<_SourceSheet> createState() => _SourceSheetState();
}

class _SourceSheetState extends ConsumerState<_SourceSheet> {
  String? _content;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final content = await ref
          .read(vaultApiServiceProvider)
          .fetchSource(widget.slug);
      if (mounted) setState(() => _content = content);
    } catch (e) {
      final message = e is HyperVaultApiException ? e.message : e.toString();
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Source',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_content != null)
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCopy01,
                      ),
                      tooltip: 'Copy source',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _content!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied!')),
                        );
                      },
                    ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : SingleChildScrollView(
                        controller: scrollController,
                        child: SelectableText(
                          _content ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
