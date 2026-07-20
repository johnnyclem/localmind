import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../../hypervault/providers/hypervault_providers.dart';
import '../../providers/hypervault_mcp_providers.dart';

/// Add-by-URL form (spec T-M11-04): url (required, http/https), optional
/// name, repeatable auth header rows. Live introspection can take up to
/// 60s server-side, so this shows a real loading state rather than a quick
/// spinner. [prefillUrl]/[prefillName]/[registryId] let the registry search
/// sheet hand off a one-tap add.
Future<void> showAddMcpServerSheet(
  BuildContext context, {
  String? prefillUrl,
  String? prefillName,
  String? registryId,
}) async {
  await showShadSheet(
    context: context,
    builder: (ctx) => _AddServerSheetContent(
      prefillUrl: prefillUrl,
      prefillName: prefillName,
      registryId: registryId,
    ),
  );
}

class _HeaderRow {
  final TextEditingController key = TextEditingController();
  final TextEditingController value = TextEditingController();

  void dispose() {
    key.dispose();
    value.dispose();
  }
}

class _AddServerSheetContent extends ConsumerStatefulWidget {
  final String? prefillUrl;
  final String? prefillName;
  final String? registryId;

  const _AddServerSheetContent({
    this.prefillUrl,
    this.prefillName,
    this.registryId,
  });

  @override
  ConsumerState<_AddServerSheetContent> createState() => _AddServerSheetContentState();
}

class _AddServerSheetContentState extends ConsumerState<_AddServerSheetContent> {
  late final TextEditingController _urlController;
  late final TextEditingController _nameController;
  final List<_HeaderRow> _headerRows = [];
  bool _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.prefillUrl ?? '');
    _nameController = TextEditingController(text: widget.prefillName ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    for (final row in _headerRows) {
      row.dispose();
    }
    super.dispose();
  }

  bool get _urlLooksValid => RegExp(r'^https?://.+').hasMatch(_urlController.text.trim());

  Future<void> _submit() async {
    final url = _urlController.text.trim();
    if (!_urlLooksValid) {
      setState(() => _error = 'Enter an absolute http(s) URL.');
      return;
    }

    final limits = ref.read(hyperVaultCapabilitiesProvider).value?.limits;
    final currentCount = ref.read(hvMcpConsoleProvider).value?.persisted.length ?? 0;
    final cap = limits?.maxMcpServers ?? 20;
    if (currentCount >= cap) {
      setState(() => _error = 'Limit of $cap MCP servers reached — remove one first.');
      return;
    }

    final headers = <String, String>{};
    for (final row in _headerRows) {
      final k = row.key.text.trim();
      final v = row.value.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) headers[k] = v;
    }

    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(hvMcpConsoleProvider.notifier)
          .addServer(
            url: url,
            name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            headers: headers.isEmpty ? null : headers,
            registryId: widget.registryId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    } on HvApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.error);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not connect: $e');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadSheet(
      title: const Text('Add MCP server'),
      description: const Text(
        'Paste a streamable-HTTP or SSE URL. It gets introspected live so its '
        'tools show up here right away.',
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ShadInputFormField(
              controller: _urlController,
              label: const Text('Server URL'),
              placeholder: const Text('https://example.com/mcp'),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ShadInputFormField(
              controller: _nameController,
              label: const Text('Name (optional)'),
              placeholder: const Text('Defaults to the server\'s own name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Auth headers (optional)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _headerRows.add(_HeaderRow())),
                  child: const Text('+ Add header'),
                ),
              ],
            ),
            for (var i = 0; i < _headerRows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ShadInputFormField(
                        controller: _headerRows[i].key,
                        placeholder: const Text('Header'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShadInputFormField(
                        controller: _headerRows[i].value,
                        placeholder: const Text('Value'),
                        obscureText: true,
                      ),
                    ),
                    IconButton(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16),
                      onPressed: () => setState(() {
                        _headerRows[i].dispose();
                        _headerRows.removeAt(i);
                      }),
                    ),
                  ],
                ),
              ),
            Text(
              'Headers are encrypted server-side and never shown again once saved.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            ShadButton(
              width: double.infinity,
              enabled: !_connecting && _urlLooksValid,
              leading: _connecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(icon: HugeIcons.strokeRoundedPlusSign, size: 16),
              onPressed: _submit,
              child: Text(_connecting ? 'Connecting… (up to 60s)' : 'Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
