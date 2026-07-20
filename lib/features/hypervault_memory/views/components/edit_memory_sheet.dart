import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../hypervault/data/models/hv_api_error.dart';
import '../../../hypervault/providers/hypervault_providers.dart';
import '../../data/models/hv_memory_detail.dart';
import '../../providers/hypervault_memory_providers.dart';

/// Edit sheet (T-M6-09): pre-fills title + content from the current
/// snapshot, PATCHes only what changed, and lands as a new git-mind commit.
Future<void> showEditMemorySheet(
  BuildContext context,
  WidgetRef ref,
  HvMemoryDetail detail,
) async {
  await showShadSheet(
    context: context,
    builder: (ctx) => _EditMemorySheetContent(detail: detail),
  );
}

class _EditMemorySheetContent extends ConsumerStatefulWidget {
  final HvMemoryDetail detail;

  const _EditMemorySheetContent({required this.detail});

  @override
  ConsumerState<_EditMemorySheetContent> createState() =>
      _EditMemorySheetContentState();
}

class _EditMemorySheetContentState
    extends ConsumerState<_EditMemorySheetContent> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.detail.memory.title);
    _contentController = TextEditingController(
      text: widget.detail.memory.content,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit(int limitBytes) async {
    final content = _contentController.text.trim();
    final bytes = hvUtf8ByteLength(content);
    if (bytes > limitBytes) {
      setState(
        () => _error =
            'That chunk is $bytes bytes — over the $limitBytes byte memory '
            'limit.',
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
      final result = await service.edit(
        widget.detail.memory.id,
        title: _titleController.text.trim(),
        content: content,
        branch: branch,
      );
      ref.invalidate(hyperVaultMemoryBrowseProvider);
      ref.invalidate(hyperVaultMemoryDetailProvider(widget.detail.memory.id));
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
      setState(() => _error = 'Could not save that edit: $e');
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
      title: const Text('Edit memory'),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ShadInputFormField(
              controller: _titleController,
              label: const Text('Title'),
            ),
            const SizedBox(height: 12),
            ShadTextarea(
              controller: _contentController,
              minHeight: 160,
              maxHeight: 320,
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
                      icon: HugeIcons.strokeRoundedFloppyDisk,
                      size: 16,
                    ),
              onPressed: () => _submit(limitBytes),
              child: const Text('Save edit'),
            ),
          ],
        ),
      ),
    );
  }
}
