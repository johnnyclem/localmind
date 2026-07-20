import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../../hypervault/providers/hypervault_providers.dart';
import '../data/models/hv_import_result.dart';
import '../providers/hv_import_providers.dart';

class _Platform {
  final String label;
  final String value; // "" means auto-detect (omit from the request).
  final String instructions;

  const _Platform(this.label, this.value, this.instructions);
}

const _platforms = [
  _Platform(
    'Auto-detect',
    '',
    'Paste anything, or pick a file — the server sniffs the shape.',
  ),
  _Platform(
    'ChatGPT',
    'chatgpt',
    'Settings → Data controls → Export data → conversations.json',
  ),
  _Platform(
    'Claude',
    'claude',
    'Settings → Privacy → Export data → conversations.json',
  ),
  _Platform(
    'Gemini',
    'gemini',
    'Google Takeout → Gemini Apps → MyActivity.json',
  ),
  _Platform(
    'Grok',
    'grok',
    'X → Settings → Your account → Download an archive',
  ),
];

/// Import AI history (spec docs/mobile/prd/12-import-history.md). File-pick
/// is offered via file_picker, but paste is the first-class peer per the
/// PRD — getting an export file onto a phone is awkward, so the paste box
/// works standalone even if picking fails or isn't available.
class HvImportScreen extends ConsumerStatefulWidget {
  const HvImportScreen({super.key});

  @override
  ConsumerState<HvImportScreen> createState() => _HvImportScreenState();
}

class _HvImportScreenState extends ConsumerState<HvImportScreen> {
  final _pasteController = TextEditingController();
  final _titleController = TextEditingController();
  String _platform = '';
  String? _pickedFileName;
  String? _pickedFileText;
  bool _busy = false;
  String? _error;
  HvImportResult? _result;

  @override
  void dispose() {
    _pasteController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  int get _importBytesLimit =>
      ref.read(hyperVaultCapabilitiesProvider).value?.limits.importBytes ??
      50000000;

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt', 'md'],
      );
      if (file == null) return; // cancelled
      final bytes = await file.readAsBytes();
      if (bytes.length > _importBytesLimit) {
        setState(() {
          _error =
              '${file.name} is ${_formatBytes(bytes.length)} — over the '
              '${_formatBytes(_importBytesLimit)} import limit.';
        });
        return;
      }
      setState(() {
        _pickedFileName = file.name;
        _pickedFileText = utf8.decode(bytes, allowMalformed: true);
      });
    } catch (e) {
      setState(() => _error = 'Could not read that file: $e');
    }
  }

  void _clearFile() {
    setState(() {
      _pickedFileName = null;
      _pickedFileText = null;
    });
  }

  Future<void> _submit() async {
    final data = _pickedFileText ?? _pasteController.text;
    if (data.trim().isEmpty) {
      setState(() => _error = 'Pick a file or paste an export to import.');
      return;
    }
    final bytes = utf8.encode(data).length;
    if (bytes > _importBytesLimit) {
      setState(() {
        _error =
            'That\'s ${_formatBytes(bytes)} — over the '
            '${_formatBytes(_importBytesLimit)} import limit.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref
          .read(hvImportServiceProvider)
          .import(
            data: data,
            platform: _platform,
            title: _titleController.text,
          );
      setState(() => _result = result);
      _pasteController.clear();
      _titleController.clear();
      _clearFile();
    } on HvApiError catch (e) {
      setState(() => _error = e.error);
    } catch (e) {
      setState(() => _error = 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _platforms.firstWhere((p) => p.value == _platform);
    final fileLoaded = _pickedFileText != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Import AI History')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Pull your ChatGPT, Claude, Gemini, or Grok history into your '
              'vault. Imported conversations show up in Chat and can be '
              'continued on any backend.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text('Platform', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _platforms)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: p.value == _platform,
                    onSelected: (_) => setState(() => _platform = p.value),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: p.value == _platform
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    selectedColor: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ShadCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      active.instructions,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('File', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (fileLoaded)
              ShadCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedFile01,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_pickedFileName — ready to import',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancelCircle,
                        size: 18,
                      ),
                      tooltip: 'Remove file',
                      onPressed: _clearFile,
                    ),
                  ],
                ),
              )
            else
              ShadButton.outline(
                width: double.infinity,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedFileImport,
                  size: 16,
                ),
                onPressed: _pickFile,
                child: const Text('Pick export file (.json / .txt / .md)'),
              ),
            const SizedBox(height: 20),
            Text('Or paste a transcript', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ShadTextarea(
              controller: _pasteController,
              enabled: !fileLoaded,
              minHeight: 140,
              maxHeight: 280,
              placeholder: Text(
                fileLoaded
                    ? 'A file is loaded — remove it to paste instead.'
                    : 'Paste your export or a transcript (speaker labels are enough)…',
              ),
            ),
            const SizedBox(height: 16),
            ShadInputFormField(
              controller: _titleController,
              label: const Text('Title (optional)'),
              placeholder: const Text('Untitled import'),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            ShadButton(
              width: double.infinity,
              enabled: !_busy,
              leading: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onPressed: _submit,
              child: Text(_busy ? 'Reconstructing your threads…' : 'Import'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final HvImportResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: Colors.green,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Import complete', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _CountBadge(label: 'Imported', count: result.imported),
              const SizedBox(width: 8),
              _CountBadge(label: 'Skipped', count: result.skipped),
            ],
          ),
          if (result.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(result.message, style: theme.textTheme.bodySmall),
          ],
          if (result.messages.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final m in result.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $m', style: theme.textTheme.bodySmall),
              ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;

  const _CountBadge({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return ShadBadge.secondary(child: Text('$count $label'));
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
