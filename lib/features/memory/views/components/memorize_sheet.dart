import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/network/hypervault_api_exception.dart';
import '../../../../core/providers/hypervault_providers.dart';
import '../../providers/memory_providers.dart';

/// Compose sheet for `POST /api/memories` (T-M6-05). Pops with the
/// server's success `message` on success, or stays open showing an inline
/// error banner on failure.
Future<String?> showMemorizeSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _MemorizeSheet(),
  );
}

class _MemorizeSheet extends ConsumerStatefulWidget {
  const _MemorizeSheet();

  @override
  ConsumerState<_MemorizeSheet> createState() => _MemorizeSheetState();
}

class _MemorizeSheetState extends ConsumerState<_MemorizeSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _sourceController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  int get _contentBytes => utf8.encode(_contentController.text).length;

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(
        () => _error = 'Content is required — paste what you want to remember.',
      );
      return;
    }

    final limitBytes =
        ref.read(capabilitiesProvider).value?.limits.memoryBytes ?? 500000;
    if (_contentBytes > limitBytes) {
      setState(
        () => _error =
            'That chunk is ${(_contentBytes / 1000).round()} kB — over the '
            '${(limitBytes / 1000).round()} kB memory limit. Split it into smaller memories.',
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(memoryApiServiceProvider)
          .create(
            content: content,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            tags: tags.isEmpty ? null : tags,
            source: _sourceController.text.trim().isEmpty
                ? null
                : _sourceController.text.trim(),
          );
      unawaited(ref.read(memoryListProvider.notifier).refresh());
      if (mounted) Navigator.of(context).pop(result.message);
    } on HyperVaultApiException catch (e) {
      if (mounted)
        setState(() {
          _submitting = false;
          _error = e.message;
        });
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error =
              'Could not memorize that — check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limitBytes =
        ref.watch(capabilitiesProvider).value?.limits.memoryBytes ?? 500000;
    final overLimit = _contentBytes > limitBytes;

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
                HugeIcon(icon: HugeIcons.strokeRoundedNote01, size: 20),
                const SizedBox(width: 8),
                Text('Memorize', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ShadInput(
              controller: _titleController,
              placeholder: const Text(
                'Title (optional — auto-generated if left blank)',
              ),
            ),
            const SizedBox(height: 12),
            ShadTextarea(
              controller: _contentController,
              placeholder: const Text('What do you want to remember?'),
              minHeight: 120,
              maxHeight: 280,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(_contentBytes / 1000).toStringAsFixed(1)} / ${(limitBytes / 1000).round()} kB',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: overLimit
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: _tagsController,
              placeholder: const Text('Tags, comma-separated (optional)'),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: _sourceController,
              placeholder: const Text('Source (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Memorize'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {}
