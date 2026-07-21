import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../../../core/providers/hypervault_providers.dart';
import '../../providers/memory_providers.dart';

const _allowedImportExtensions = [
  'pdf',
  'docx',
  'md',
  'markdown',
  'mdx',
  'txt',
];

/// Import sheet for `POST /api/memories/import` (T-M6-06/07) — a file
/// (PDF/DOCX/md/txt) via [FilePicker], or a GitHub repo / web page URL.
/// Both hit the same endpoint; only the body shape differs. Pops with the
/// server's success `message` on success.
Future<String?> showImportMemorySheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _ImportSheet(),
  );
}

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final _urlController = TextEditingController();

  bool _busy = false;
  String? _busyLabel;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndImportFile() async {
    setState(() => _error = null);

    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _allowedImportExtensions,
      );
    } catch (_) {
      setState(() => _error = 'Could not open the file picker.');
      return;
    }
    if (file == null) return; // user canceled

    final limitBytes =
        ref.read(capabilitiesProvider).value?.limits.importBytes ?? 50000000;
    if (file.size > limitBytes) {
      setState(
        () => _error =
            '${file!.name} is ${(file.size / 1000000).toStringAsFixed(1)} MB — over the '
            '${(limitBytes / 1000000).round()} MB import limit.',
      );
      return;
    }

    setState(() {
      _busy = true;
      _busyLabel = 'Importing file…';
      _error = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final result = await ref
          .read(memoryApiServiceProvider)
          .importFile(bytes: bytes, filename: file.name);
      unawaited(ref.read(memoryListProvider.notifier).refresh());
      if (mounted) Navigator.of(context).pop(result.message);
    } on HyperVaultApiException catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = e.message;
        });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Import failed — check your connection and try again.';
        });
      }
    }
  }

  Future<void> _importUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Paste a GitHub repo or web page URL first.');
      return;
    }

    setState(() {
      _busy = true;
      _busyLabel = 'Importing URL…';
      _error = null;
    });

    try {
      final result = await ref.read(memoryApiServiceProvider).importUrl(url);
      unawaited(ref.read(memoryListProvider.notifier).refresh());
      if (mounted) Navigator.of(context).pop(result.message);
    } on HyperVaultApiException catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = e.message;
        });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Import failed — check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedFileUpload, size: 20),
                const SizedBox(width: 8),
                Text('Import', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Import a PDF, DOCX, Markdown, or text file',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ShadButton.outline(
                onPressed: _busy ? null : _pickAndImportFile,
                leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAttachment01,
                  size: 16,
                ),
                child: const Text('Choose a file'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('or', style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Import a GitHub repo or web page URL',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ShadInput(
              controller: _urlController,
              placeholder: const Text(
                'https://github.com/owner/repo or any URL',
              ),
              enabled: !_busy,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: _busy ? null : _importUrl,
                child: const Text('Import URL'),
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(_busyLabel ?? 'Importing…'),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {}
