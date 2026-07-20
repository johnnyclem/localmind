import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../data/models/hv_backend.dart';
import '../providers/hypervault_backends_providers.dart';
import 'components/hypervault_provider_picker.dart';

/// Connect (T-M10-03/04/05) or edit (T-M10-06) a backend. Provider is fixed
/// once connected — [editing] non-null means edit mode. Runs the server's
/// live connection test (`maxDuration 60`) on submit; the server's
/// `{error}`/success `message` are shown verbatim.
class HyperVaultBackendFormScreen extends ConsumerStatefulWidget {
  final List<HvProviderSpec> providers;
  final HvBackend? editing;

  const HyperVaultBackendFormScreen({
    super.key,
    required this.providers,
    this.editing,
  });

  @override
  ConsumerState<HyperVaultBackendFormScreen> createState() =>
      _HyperVaultBackendFormScreenState();
}

class _HyperVaultBackendFormScreenState
    extends ConsumerState<HyperVaultBackendFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _defaultModelController;
  late final TextEditingController _embeddingModelController;

  String? _providerId;
  bool _busy = false;
  bool _deleting = false;
  String? _errorText;

  bool get _isEditing => widget.editing != null;

  HvProviderSpec? get _spec {
    for (final spec in widget.providers) {
      if (spec.id == _providerId) return spec;
    }
    return widget.providers.isNotEmpty ? widget.providers.first : null;
  }

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _providerId =
        editing?.provider ??
        (widget.providers.isNotEmpty ? widget.providers.first.id : null);
    _nameController = TextEditingController(text: editing?.name ?? '');
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController(text: editing?.baseUrl ?? '');
    _defaultModelController = TextEditingController(
      text: editing?.defaultModel ?? '',
    );
    _embeddingModelController = TextEditingController(
      text: editing?.embeddingModel ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _defaultModelController.dispose();
    _embeddingModelController.dispose();
    super.dispose();
  }

  bool get _isLocalRuntime {
    final spec = _spec;
    final baseUrl = _baseUrlController.text.trim().toLowerCase();
    return (spec?.isLocalRuntime ?? false) ||
        baseUrl.contains('localhost') ||
        baseUrl.contains('127.0.0.1');
  }

  Future<void> _submit() async {
    final spec = _spec;
    if (spec == null) {
      setState(() => _errorText = 'No provider is available on this server.');
      return;
    }

    final name = _nameController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    final defaultModel = _defaultModelController.text.trim();
    final embeddingModel = _embeddingModelController.text.trim();

    if (!_isEditing && spec.requiresKey && apiKey.isEmpty) {
      setState(() => _errorText = '${spec.label} needs an API key.');
      return;
    }
    if (spec.isCustom && baseUrl.isEmpty) {
      setState(() => _errorText = 'Custom endpoints need a base URL.');
      return;
    }
    if (spec.isCustom && !_isEditing && defaultModel.isEmpty) {
      setState(() => _errorText = 'Custom endpoints need a default model.');
      return;
    }

    setState(() {
      _errorText = null;
      _busy = true;
    });

    try {
      final notifier = ref.read(hyperVaultBackendsProvider.notifier);
      final result = _isEditing
          ? await notifier.editBackend(
              id: widget.editing!.id,
              name: name.isEmpty ? spec.label : name,
              baseUrl: baseUrl,
              defaultModel: defaultModel,
              embeddingModel: spec.supportsEmbeddings ? embeddingModel : null,
              apiKey: apiKey.isEmpty ? null : apiKey,
            )
          : await notifier.addBackend(
              provider: spec.id,
              name: name.isEmpty ? null : name,
              apiKey: apiKey.isEmpty ? null : apiKey,
              baseUrl: baseUrl.isEmpty ? null : baseUrl,
              defaultModel: defaultModel.isEmpty ? null : defaultModel,
              embeddingModel: embeddingModel.isEmpty ? null : embeddingModel,
            );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on HvApiError catch (e) {
      setState(() => _errorText = e.error);
    } catch (e) {
      setState(() => _errorText = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final editing = widget.editing;
    if (editing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disconnect backend?'),
        content: Text(
          'This removes "${editing.name}" from your connected backends. '
          'This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final message = await ref
          .read(hyperVaultBackendsProvider.notifier)
          .removeBackend(editing.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on HvApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.error)));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = _spec;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit backend' : 'Connect a backend'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: Colors.red,
                    ),
              onPressed: _deleting ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorText != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!_isEditing) ...[
                Text('Provider', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                HyperVaultProviderPicker(
                  providers: widget.providers,
                  selectedId: _providerId,
                  onChanged: (id) => setState(() => _providerId = id),
                ),
              ] else ...[
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCloudServer,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${spec?.label ?? widget.editing!.provider} · provider is fixed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              ShadInputFormField(
                controller: _nameController,
                label: const Text('Name'),
                placeholder: Text(spec?.label ?? 'Backend name'),
              ),
              const SizedBox(height: 14),
              ShadInputFormField(
                controller: _apiKeyController,
                obscureText: true,
                label: const Text('API key'),
                placeholder: Text(
                  _isEditing
                      ? (widget.editing!.keyHint ??
                            'Leave blank to keep current key')
                      : (spec?.requiresKey ?? false)
                      ? 'Required'
                      : 'Optional',
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 4),
                Text(
                  'Leave blank to keep the current key.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ShadInputFormField(
                controller: _baseUrlController,
                onChanged: (_) => setState(() {}),
                label: const Text('Base URL'),
                placeholder: Text(
                  (spec?.defaultBaseUrl.isNotEmpty ?? false)
                      ? spec!.defaultBaseUrl
                      : 'https://…',
                ),
              ),
              if (_isLocalRuntime) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'On a phone, "localhost" is the phone itself. '
                          'HyperVault\'s server makes this call, so use a '
                          'LAN IP or a tunnel URL (ngrok, Tailscale Funnel) '
                          'that reaches your runtime — not localhost.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ShadInputFormField(
                controller: _defaultModelController,
                label: const Text('Default model'),
                placeholder: Text(
                  (spec?.defaultModel.isNotEmpty ?? false)
                      ? spec!.defaultModel
                      : 'model name',
                ),
              ),
              if (spec?.supportsEmbeddings ?? false) ...[
                const SizedBox(height: 14),
                ShadInputFormField(
                  controller: _embeddingModelController,
                  label: const Text('Embedding model (optional)'),
                  placeholder: Text(
                    spec?.defaultEmbeddingModel ??
                        'e.g. text-embedding-3-small',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enables semantic recall for this backend — verified on '
                  'connect against a 1536-dimension embedding.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ShadButton(
                width: double.infinity,
                enabled: !_busy && spec != null,
                leading: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onPressed: _submit,
                child: Text(
                  _busy
                      ? (_isEditing
                            ? 'Re-verifying the endpoint…'
                            : 'Testing the endpoint…')
                      : (_isEditing ? 'Save changes' : 'Connect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
