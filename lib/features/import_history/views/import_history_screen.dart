import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../data/models/import_history_result.dart';
import '../providers/import_history_providers.dart';
import 'components/import_result_card.dart';

/// Import AI History screen (mobile PRD M12): pick a platform, supply an
/// export either by file or pasted text, and `POST /api/import` it into the
/// vault. Reachable at [AppRoutes.importHistory] ('/import').
class ImportHistoryScreen extends ConsumerStatefulWidget {
  const ImportHistoryScreen({super.key});

  @override
  ConsumerState<ImportHistoryScreen> createState() =>
      _ImportHistoryScreenState();
}

class _ImportHistoryScreenState extends ConsumerState<ImportHistoryScreen> {
  // The server's maxDuration is 60s; the progress bar creeps toward (not
  // past) full over this window so it stays honestly "determinate but slow"
  // rather than snapping to 100% before the response actually lands.
  static const _expectedDuration = Duration(seconds: 60);

  ImportPlatform _platform = ImportPlatform.auto;
  int _sourceTab = 0; // 0 = pick file, 1 = paste transcript

  PlatformFile? _pickedFile;
  String? _fileText;
  final _pasteController = TextEditingController();

  bool _busy = false;
  double _progress = 0;
  Timer? _progressTimer;
  final _stopwatch = Stopwatch();

  String? _fileError;
  String? _submitError;
  ImportHistoryResult? _result;

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pasteController.dispose();
    super.dispose();
  }

  String? get _payload {
    // File wins if both are populated.
    final fileText = _fileText;
    if (fileText != null && fileText.trim().isNotEmpty) return fileText;
    final pasted = _pasteController.text;
    return pasted.trim().isEmpty ? null : pasted;
  }

  Future<void> _pickFile() async {
    setState(() {
      _fileError = null;
      _result = null;
      _submitError = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt', 'md'],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) return; // user cancelled

      final bytes = await file.readAsBytes();
      final String text;
      try {
        text = utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        setState(() {
          _pickedFile = null;
          _fileText = null;
          _fileError =
              "That file isn't valid UTF-8 text — zip archives and other "
              'binary exports are not supported yet. Unzip it and pick the '
              'JSON/text file inside, or paste the transcript instead.';
        });
        return;
      }

      setState(() {
        _pickedFile = file;
        _fileText = text;
      });
    } catch (e) {
      setState(() {
        _fileError = 'Could not read that file: $e';
      });
    }
  }

  void _clearFile() {
    setState(() {
      _pickedFile = null;
      _fileText = null;
      _fileError = null;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1000000) return '${(bytes / 1000000).toStringAsFixed(1)} MB';
    if (bytes >= 1000) return '${(bytes / 1000).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  Future<void> _submit() async {
    final data = _payload;
    if (data == null) return;

    final limits = ref.read(capabilitiesProvider).value?.limits;
    final maxBytes = limits?.importBytes ?? 50000000;
    final byteLength = utf8.encode(data).length;
    if (byteLength > maxBytes) {
      setState(() {
        _submitError =
            'This export is ${_formatBytes(byteLength)}, over the '
            '${_formatBytes(maxBytes)} import limit. Split it into smaller '
            'pieces and import each separately.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _submitError = null;
      _result = null;
      _progress = 0;
    });

    _stopwatch
      ..reset()
      ..start();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      final elapsedMs = _stopwatch.elapsedMilliseconds;
      final fraction = elapsedMs / _expectedDuration.inMilliseconds;
      if (!mounted) return;
      setState(() {
        _progress = fraction.clamp(0.0, 0.95);
      });
    });

    try {
      final api = ref.read(importHistoryApiServiceProvider);
      final result = await api.importHistory(
        data: data,
        platform: _platform.apiValue,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _progress = 1;
        _pickedFile = null;
        _fileText = null;
        _pasteController.clear();
      });
    } on HyperVaultApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError =
            'Network hiccup — your export is safe locally, try again.';
      });
    } finally {
      _progressTimer?.cancel();
      _stopwatch.stop();
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canSubmit = !_busy && _payload != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Import AI History')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Pull your history out of ChatGPT, Claude, Gemini, or Grok and '
              'into your vault. Imported conversations show up in Chat and '
              'can be continued on any backend.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text('Platform', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ImportPlatform.values.map((p) {
                final selected = p == _platform;
                return selected
                    ? ShadButton(
                        onPressed: () => setState(() => _platform = p),
                        child: Text(p.label),
                      )
                    : ShadButton.outline(
                        onPressed: () => setState(() => _platform = p),
                        child: Text(p.label),
                      );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _platform.instructions,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ShadTabs<int>(
              value: _sourceTab,
              onChanged: (v) => setState(() => _sourceTab = v),
              tabs: [
                ShadTab(
                  value: 0,
                  content: _buildFileTab(theme, colorScheme),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedFile02,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text('Pick file'),
                    ],
                  ),
                ),
                ShadTab(
                  value: 1,
                  content: _buildPasteTab(theme),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedClipboardPaste,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text('Paste transcript'),
                    ],
                  ),
                ),
              ],
            ),
            if (_fileError != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _fileError!, colorScheme: colorScheme),
            ],
            const SizedBox(height: 20),
            if (_busy) ...[
              Text(
                'Reconstructing your threads…',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              ShadProgress(value: _progress),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: canSubmit ? _submit : null,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(icon: HugeIcons.strokeRoundedFileUpload),
              label: Text(_busy ? 'Reconstructing your threads…' : 'Import'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: _submitError!, colorScheme: colorScheme),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              ImportResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileTab(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadButton.outline(
            leading: const HugeIcon(icon: HugeIcons.strokeRoundedFileUpload),
            onPressed: _pickFile,
            child: const Text('Choose export file (.json, .txt, .md)'),
          ),
          if (_pickedFile != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Loaded ${_pickedFile!.name} — ready to import.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 18,
                  ),
                  tooltip: 'Remove',
                  onPressed: _clearFile,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasteTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ShadTextarea(
        controller: _pasteController,
        placeholder: const Text(
          'User: how do I center a div\nAssistant: with flexbox — …',
        ),
        minHeight: 180,
        maxHeight: 320,
        enabled: _pickedFile == null,
        onChanged: (_) {
          if (_result != null || _submitError != null) {
            setState(() {
              _result = null;
              _submitError = null;
            });
          }
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final ColorScheme colorScheme;

  const _ErrorBanner({required this.message, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Text(message, style: TextStyle(color: colorScheme.error)),
    );
  }
}
