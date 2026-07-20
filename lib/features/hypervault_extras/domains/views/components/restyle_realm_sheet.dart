import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../hypervault/data/models/hv_api_error.dart';
import '../../../../hypervault/data/models/hv_capabilities.dart';
import '../../data/models/hv_domain_claim.dart';
import '../../providers/hv_domains_providers.dart';

/// Per-realm theme picker (spec T-M13-07). Optimistic select with rollback
/// on failure — updates [HvClaimedRealmsNotifier] directly so the caller's
/// list repaints without a manual refresh.
Future<void> showRestyleRealmSheet(
  BuildContext context, {
  required HvClaimedRealm realm,
  required List<HvTheme> themes,
}) async {
  await showShadSheet(
    context: context,
    builder: (ctx) => _RestyleSheetContent(realm: realm, themes: themes),
  );
}

class _RestyleSheetContent extends ConsumerStatefulWidget {
  final HvClaimedRealm realm;
  final List<HvTheme> themes;

  const _RestyleSheetContent({required this.realm, required this.themes});

  @override
  ConsumerState<_RestyleSheetContent> createState() =>
      _RestyleSheetContentState();
}

class _RestyleSheetContentState extends ConsumerState<_RestyleSheetContent> {
  String? _selected;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.realm.theme;
  }

  Future<void> _save(String? theme) async {
    final previous = _selected;
    setState(() {
      _selected = theme;
      _saving = true;
      _error = null;
    });
    final subdomain = widget.realm.domain.split('.').first;
    final baseDomain = widget.realm.domain.substring(subdomain.length + 1);
    try {
      final result = await ref
          .read(hvDomainsServiceProvider)
          .restyle(subdomain: subdomain, baseDomain: baseDomain, theme: theme);
      ref
          .read(hvClaimedRealmsProvider.notifier)
          .setTheme(widget.realm.domain, result.theme);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on HvApiError catch (e) {
      setState(() {
        _selected = previous;
        _error = e.error;
      });
    } catch (e) {
      setState(() {
        _selected = previous;
        _error = 'Could not restyle: $e';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadSheet(
      title: Text('Restyle ${widget.realm.domain}'),
      description: const Text('Changes what visitors see at this address.'),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Domain default'),
                  selected: _selected == null,
                  onSelected: _saving ? null : (_) => _save(null),
                ),
                for (final t in widget.themes)
                  ChoiceChip(
                    label: Text(t.name),
                    selected: _selected == t.id,
                    onSelected: _saving ? null : (_) => _save(t.id),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ],
            if (_saving) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
