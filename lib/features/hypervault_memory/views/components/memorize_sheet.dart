import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../../hypervault/providers/hypervault_providers.dart';
import '../../providers/hypervault_memory_providers.dart';

/// "Memorize" compose sheet (T-M6-05): content is required and capped at
/// `capabilities.limits.memoryBytes` client-side; title/tags are optional.
Future<void> showMemorizeSheet(BuildContext context, WidgetRef ref) async {
  await showShadSheet(
    context: context,
    builder: (ctx) => const _MemorizeSheetContent(),
  );
}

class _MemorizeSheetContent extends ConsumerStatefulWidget {
  const _MemorizeSheetContent();

  @override
  ConsumerState<_MemorizeSheetContent> createState() =>
      _MemorizeSheetContentState();
}

class _MemorizeSheetContentState extends ConsumerState<_MemorizeSheetContent> {
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit(int limitBytes) async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Write something to memorize first.');
      return;
    }
    final bytes = hvUtf8ByteLength(content);
    if (bytes > limitBytes) {
      setState(
        () => _error =
            'That chunk is $bytes bytes — over the $limitBytes byte memory '
            'limit. Split it into smaller memories.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final service = ref.read(hyperVaultMemoryServiceProvider);
      final branch = ref.read(hyperVaultActiveBranchProvider);
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final result = await service.memorize(
        content: content,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        tags: tags.isEmpty ? null : tags,
        branch: branch,
      );
      ref.invalidate(hyperVaultMemoryBrowseProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on HvApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.error);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not memorize that: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final limits = ref.watch(hyperVaultCapabilitiesProvider).value?.limits;
    final limitBytes = limits?.memoryBytes ?? 500000;
    final bytes = hvUtf8ByteLength(_contentController.text);
    final over = bytes > limitBytes;

    return ShadSheet(
      title: const Text('Memorize'),
      description: const Text(
        'Paste a chunk worth keeping — it comes back auto-titled, summarized, and tagged.',
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ShadTextarea(
              controller: _contentController,
              placeholder: const Text('What do you want to remember?'),
              minHeight: 140,
              maxHeight: 280,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              '$bytes / $limitBytes bytes',
              style: TextStyle(
                fontSize: 11,
                color: over ? Colors.red : Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 12),
            ShadInputFormField(
              controller: _titleController,
              label: const Text('Title (optional)'),
              placeholder: const Text('Auto-titled if left blank'),
            ),
            const SizedBox(height: 12),
            ShadInputFormField(
              controller: _tagsController,
              label: const Text('Tags (optional, comma-separated)'),
              placeholder: const Text('e.g. project-x, ideas'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            ShadButton(
              width: double.infinity,
              enabled: !_saving,
              leading: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedBrain,
                      size: 16,
                    ),
              onPressed: () => _submit(limitBytes),
              child: const Text('Memorize'),
            ),
          ],
        ),
      ),
    );
  }
}
