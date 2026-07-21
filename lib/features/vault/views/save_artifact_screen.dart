import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../../core/widgets/hv_error_toast.dart';
import '../data/models/artifact.dart';
import '../providers/vault_providers.dart';

/// "New from chat" save form (mobile PRD T-M3-07/T-M3-08). Pastes
/// AI-generated HTML/JSX, optionally keeps the source prompt, and posts to
/// `POST /api/save`.
class SaveArtifactScreen extends ConsumerStatefulWidget {
  const SaveArtifactScreen({super.key});

  @override
  ConsumerState<SaveArtifactScreen> createState() => _SaveArtifactScreenState();
}

class _SaveArtifactScreenState extends ConsumerState<SaveArtifactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _sourcePromptController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isPrivate = true;
  bool _makePwa = true;
  bool _forceHtml = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourcePromptController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(20)
        .toList();
  }

  Future<void> _save() async {
    setState(() {
      _errorMessage = null;
    });

    final content = _contentController.text;
    if (content.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Paste some content before saving.';
      });
      return;
    }

    final limits = ref.read(capabilitiesProvider).value?.limits;
    final contentBytes = utf8.encode(content).length;
    if (limits != null && contentBytes > limits.artifactBytes) {
      setState(() {
        _errorMessage =
            'Content is ${(contentBytes / 1000).round()} KB, which is over '
            'the ${(limits.artifactBytes / 1000).round()} KB limit.';
      });
      return;
    }

    final sourcePrompt = _sourcePromptController.text;
    if (limits != null &&
        sourcePrompt.trim().isNotEmpty &&
        sourcePrompt.length > limits.sourcePromptChars) {
      setState(() {
        _errorMessage =
            'Source prompt is ${sourcePrompt.length} characters, over the '
            '${limits.sourcePromptChars}-character limit.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ref
          .read(vaultApiServiceProvider)
          .saveArtifact(
            content: content,
            title: _titleController.text,
            tags: _parseTags(_tagsController.text),
            makePwa: _makePwa,
            forceHtml: _forceHtml,
            visibility: _isPrivate ? 'private' : 'public',
            sourcePrompt: sourcePrompt,
          );

      if (!mounted) return;
      await ref.read(vaultListProvider.notifier).refresh();
      if (!mounted) return;
      await _showResultDialog(result);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on HyperVaultApiException catch (e) {
      if (mounted) showHvError(context, e);
    } catch (e) {
      if (mounted) showHvError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showResultDialog(SaveArtifactResult result) {
    return showShadDialog<void>(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(result.duplicate ? 'Already in your vault' : 'Saved'),
        description: Text(
          result.message.isNotEmpty
              ? result.message
              : (result.duplicate
                    ? 'This matches an existing artifact.'
                    : 'Your artifact is live.'),
        ),
        actions: [
          ShadButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  result.url,
                  style: const TextStyle(fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCopy01),
                tooltip: 'Copy link',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.url));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Save artifact')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Untitled',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Text('Content', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              'Paste the HTML/JSX your AI generated.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              maxLines: 12,
              minLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '<html>...</html>',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Source prompt (optional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sourcePromptController,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'The prompt that produced this artifact',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated, optional)',
                hintText: 'landing-page, react, demo',
              ),
            ),
            const SizedBox(height: 20),
            ShadSwitch(
              value: !_isPrivate,
              onChanged: (v) => setState(() => _isPrivate = !v),
              label: const Text('Public'),
              sublabel: Text(
                _isPrivate
                    ? 'Only you can view this artifact.'
                    : 'Anyone with the link can view this artifact.',
              ),
            ),
            const SizedBox(height: 12),
            ShadSwitch(
              value: _makePwa,
              onChanged: (v) => setState(() => _makePwa = v),
              label: const Text('Make it installable'),
              sublabel: const Text(
                'Adds a PWA manifest so it can be added to a home screen.',
              ),
            ),
            const SizedBox(height: 12),
            ShadSwitch(
              value: _forceHtml,
              onChanged: (v) => setState(() => _forceHtml = v),
              label: const Text('Force plain HTML'),
              sublabel: const Text(
                'Skips React/JSX auto-detection (done server-side).',
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(icon: HugeIcons.strokeRoundedFloppyDisk),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
