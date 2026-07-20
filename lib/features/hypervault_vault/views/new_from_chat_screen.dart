import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../../hypervault/providers/hypervault_providers.dart';
import '../data/hv_vault_format.dart';
import '../data/models/hv_artifact.dart';
import '../providers/hv_vault_providers.dart';

/// "New from chat" save flow (docs/mobile/prd/03-vault-artifacts.md
/// T-M3-07/08/09): paste something an AI made and `POST /api/save` it.
class NewFromChatScreen extends ConsumerStatefulWidget {
  /// Prefills the source-prompt field — wire this from the
  /// `?source_prompt=` deep link once M16 routing lands (see integration
  /// notes); no-op when omitted.
  final String? initialSourcePrompt;

  const NewFromChatScreen({super.key, this.initialSourcePrompt});

  @override
  ConsumerState<NewFromChatScreen> createState() => _NewFromChatScreenState();
}

class _NewFromChatScreenState extends ConsumerState<NewFromChatScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _sourcePromptController = TextEditingController();
  final _tagsController = TextEditingController();
  final _connectToController = TextEditingController();

  bool _private = true;
  bool _makePwa = true;
  bool _forceHtml = false;
  bool _saving = false;
  String? _error;
  HvSaveResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialSourcePrompt != null) {
      _sourcePromptController.text = widget.initialSourcePrompt!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourcePromptController.dispose();
    _tagsController.dispose();
    _connectToController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limits = ref.read(hyperVaultCapabilitiesProvider).value?.limits;
    final content = _contentController.text;
    final sourcePrompt = _sourcePromptController.text.trim();

    final maxBytes = limits?.artifactBytes ?? 1000000;
    final maxPromptChars = limits?.sourcePromptChars ?? 10000;

    final contentBytes = hvUtf8ByteLength(content);
    if (contentBytes > maxBytes) {
      setState(() => _error = 'Content is $contentBytes bytes — the limit is $maxBytes.');
      return;
    }
    if (sourcePrompt.length > maxPromptChars) {
      setState(
        () => _error =
            'Source prompt is ${sourcePrompt.length} characters — the limit is $maxPromptChars.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final connectTo = _connectToController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final result = await ref.read(hvVaultServiceProvider).save(
            content: content,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
            tags: tags,
            connectTo: connectTo,
            makePwa: _makePwa,
            forceHtml: _forceHtml,
            visibility: _private ? 'private' : 'public',
            sourcePrompt: sourcePrompt.isEmpty ? null : sourcePrompt,
          );

      if (!result.duplicate) {
        await ref.read(hvArtifactsProvider.notifier).prepend(
              HvArtifact(
                slug: result.slug,
                title: _titleController.text.trim().isEmpty
                    ? 'Untitled'
                    : _titleController.text.trim(),
                type: 'html',
                tags: tags,
                sourcePrompt: sourcePrompt.isEmpty ? null : sourcePrompt,
                isPwa: result.isPwa,
                isJsx: result.isJsx,
                visibility: result.visibility,
                createdAt: DateTime.now(),
                url: result.url,
              ),
            );
      }

      setState(() => _result = result);
    } on HvApiError catch (e) {
      setState(() => _error = e.error);
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New from chat')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_result != null)
                _ResultCard(result: _result!, onSaveAnother: () {
                  setState(() {
                    _result = null;
                    _contentController.clear();
                    _titleController.clear();
                    _sourcePromptController.clear();
                    _tagsController.clear();
                    _connectToController.clear();
                  });
                })
              else ...[
                ShadInputFormField(
                  controller: _titleController,
                  label: const Text('Title'),
                  placeholder: const Text('Untitled'),
                ),
                const SizedBox(height: 12),
                Text('Paste from chat', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                ShadTextarea(
                  controller: _contentController,
                  placeholder: const Text('Paste the HTML/JSX/markup your AI made…'),
                  minHeight: 160,
                  maxHeight: 320,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  controller: _sourcePromptController,
                  label: const Text('Source prompt (optional)'),
                  placeholder: const Text('What prompt made this?'),
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  controller: _connectToController,
                  label: const Text('Connect to (optional, comma-separated titles/slugs)'),
                  placeholder: const Text('e.g. my-other-artifact'),
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  controller: _tagsController,
                  label: const Text('Tags (optional, comma-separated)'),
                  placeholder: const Text('e.g. project-x, ideas'),
                ),
                const SizedBox(height: 16),
                ShadSwitch(
                  value: _private,
                  onChanged: (v) => setState(() => _private = v),
                  label: const Text('Keep it private'),
                ),
                const SizedBox(height: 8),
                ShadSwitch(
                  value: _makePwa,
                  onChanged: (v) => setState(() => _makePwa = v),
                  label: const Text('Make it installable'),
                ),
                const SizedBox(height: 8),
                ShadSwitch(
                  value: _forceHtml,
                  onChanged: (v) => setState(() => _forceHtml = v),
                  label: const Text('Force plain HTML'),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2),
                  child: Text(
                    'JSX/React auto-detection happens on the server; force plain '
                    'HTML to skip it.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),
                ShadButton(
                  width: double.infinity,
                  enabled: !_saving && _contentController.text.trim().isNotEmpty,
                  leading: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onPressed: _save,
                  child: Text(_saving ? 'Saving…' : 'Save to vault'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final HvSaveResult result;
  final VoidCallback onSaveAnother;

  const _ResultCard({required this.result, required this.onSaveAnother});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: result.duplicate
                    ? HugeIcons.strokeRoundedCopy01
                    : HugeIcons.strokeRoundedCheckmarkCircle01,
                color: result.duplicate ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Clipboard.setData(ClipboardData(text: result.url)),
            child: Text(
              result.url,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ShadButton.outline(
            onPressed: onSaveAnother,
            child: const Text('Save another'),
          ),
        ],
      ),
    );
  }
}
