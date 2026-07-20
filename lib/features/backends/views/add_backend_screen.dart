import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/models/hypervault_capabilities.dart';
import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../../core/utils/system_insets.dart';
import '../data/models/backend.dart';
import '../data/provider_registry.dart';
import '../providers/backends_providers.dart';

class AddBackendScreen extends ConsumerStatefulWidget {
  final Backend? editBackend;

  const AddBackendScreen({super.key, this.editBackend});

  @override
  ConsumerState<AddBackendScreen> createState() => _AddBackendScreenState();
}

class _AddBackendScreenState extends ConsumerState<AddBackendScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _defaultModelController;
  late TextEditingController _embeddingModelController;

  late String _selectedProviderId;
  bool _isSaving = false;
  String? _errorText;

  bool get _isEditing => widget.editBackend != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editBackend;

    _nameController = TextEditingController(text: editing?.name ?? '');
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController(text: editing?.baseUrl ?? '');
    _defaultModelController = TextEditingController(
      text: editing?.defaultModel ?? '',
    );
    _embeddingModelController = TextEditingController(
      text: editing?.embeddingModel ?? '',
    );
    _baseUrlController.addListener(_onBaseUrlChanged);

    final providers = _providers;
    _selectedProviderId =
        editing?.provider ??
        (providers.isNotEmpty
            ? providers.first.id
            : fallbackProviders.first.id);

    if (!_isEditing) {
      _applyProviderDefaults(_specFor(_selectedProviderId));
    }
  }

  @override
  void dispose() {
    _baseUrlController.removeListener(_onBaseUrlChanged);
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _defaultModelController.dispose();
    _embeddingModelController.dispose();
    super.dispose();
  }

  void _onBaseUrlChanged() => setState(() {});

  List<HyperVaultProvider> get _providers {
    final loaded = ref.read(capabilitiesProvider).value?.providers ?? const [];
    return loaded.isNotEmpty ? loaded : fallbackProviders;
  }

  HyperVaultProvider _specFor(String id) {
    return _providers.firstWhere(
      (p) => p.id == id,
      orElse: () => HyperVaultProvider(id: id, raw: {'id': id}),
    );
  }

  bool _requiresKey(HyperVaultProvider spec) =>
      providerRawBool(spec, 'requiresKey');
  bool _optionalKey(HyperVaultProvider spec) =>
      providerRawBool(spec, 'optionalKey');
  bool _showApiKeyField(HyperVaultProvider spec) =>
      _requiresKey(spec) ||
      _optionalKey(spec) ||
      (!spec.raw.containsKey('requiresKey') &&
          !spec.raw.containsKey('optionalKey'));

  bool _baseUrlRequired() => isLocalOrCustomProviderId(_selectedProviderId);

  bool _modelRequired() =>
      _selectedProviderId.toLowerCase().startsWith('custom');

  bool _showBaseUrlField(HyperVaultProvider spec) {
    final defaultBaseUrl = providerRawString(spec, 'defaultBaseUrl');
    return _baseUrlRequired() ||
        (defaultBaseUrl != null && defaultBaseUrl.isNotEmpty) ||
        (widget.editBackend?.baseUrl?.isNotEmpty ?? false);
  }

  bool _showEmbeddingField(HyperVaultProvider spec) =>
      providerRawString(spec, 'protocol') == 'openai';

  bool _showLocalRuntimeCaveat() {
    return isLocalOrCustomProviderId(_selectedProviderId) &&
            (_selectedProviderId.toLowerCase() == 'ollama' ||
                _selectedProviderId.toLowerCase() == 'lm_studio' ||
                _selectedProviderId.toLowerCase() == 'lmstudio') ||
        isLocalhostUrl(_baseUrlController.text);
  }

  void _applyProviderDefaults(HyperVaultProvider spec) {
    final defaultBaseUrl = providerRawString(spec, 'defaultBaseUrl');
    final defaultModel = providerRawString(spec, 'defaultModel');
    final defaultEmbeddingModel = providerRawString(
      spec,
      'defaultEmbeddingModel',
    );

    if (defaultBaseUrl != null && defaultBaseUrl.isNotEmpty) {
      _baseUrlController.text = defaultBaseUrl;
    }
    if (defaultModel != null && defaultModel.isNotEmpty) {
      _defaultModelController.text = defaultModel;
    }
    if (defaultEmbeddingModel != null && defaultEmbeddingModel.isNotEmpty) {
      _embeddingModelController.text = defaultEmbeddingModel;
    }
  }

  void _onProviderChanged(String? providerId) {
    if (providerId == null || providerId == _selectedProviderId) return;
    setState(() {
      _selectedProviderId = providerId;
      _errorText = null;
      _nameController.clear();
      _apiKeyController.clear();
      _baseUrlController.clear();
      _defaultModelController.clear();
      _embeddingModelController.clear();
      _applyProviderDefaults(_specFor(providerId));
    });
  }

  /// Reactive variant for use inside [build] — subscribes so the Save
  /// button's disabled state updates live if the backend count/limit
  /// changes while this screen is open.
  bool _limitReachedWatch() {
    if (_isEditing) return false;
    final max = ref.watch(capabilitiesProvider).value?.limits.maxBackends ?? 20;
    final current = ref.watch(backendsProvider).value?.backends.length ?? 0;
    return current >= max;
  }

  /// Non-reactive variant for use in callbacks (e.g. [_save]) — `ref.watch`
  /// is only safe to call from `build`.
  bool _limitReachedRead() {
    if (_isEditing) return false;
    final max = ref.read(capabilitiesProvider).value?.limits.maxBackends ?? 20;
    final current = ref.read(backendsProvider).value?.backends.length ?? 0;
    return current >= max;
  }

  Future<void> _save() async {
    if (_limitReachedRead()) {
      setState(() {
        _errorText =
            "You've reached the limit of connected backends. "
            'Remove one before adding another.';
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final name = _nameController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    final defaultModel = _defaultModelController.text.trim();
    final embeddingModel = _embeddingModelController.text.trim();

    try {
      final result = _isEditing
          ? await ref
                .read(backendsProvider.notifier)
                .updateBackend(
                  id: widget.editBackend!.id,
                  name: name.isEmpty ? null : name,
                  apiKey: apiKey.isEmpty ? null : apiKey,
                  baseUrl: baseUrl.isEmpty ? null : baseUrl,
                  defaultModel: defaultModel.isEmpty ? null : defaultModel,
                  embeddingModel: embeddingModel.isEmpty
                      ? null
                      : embeddingModel,
                )
          : await ref
                .read(backendsProvider.notifier)
                .addBackend(
                  provider: _selectedProviderId,
                  name: name.isEmpty ? null : name,
                  apiKey: apiKey.isEmpty ? null : apiKey,
                  baseUrl: baseUrl.isEmpty ? null : baseUrl,
                  defaultModel: defaultModel.isEmpty ? null : defaultModel,
                  embeddingModel: embeddingModel.isEmpty
                      ? null
                      : embeddingModel,
                );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } on HyperVaultApiException catch (e) {
      setState(() {
        _errorText = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateApiKey(String? value) {
    if (_isEditing) return null;
    final spec = _specFor(_selectedProviderId);
    if (_requiresKey(spec) && (value == null || value.trim().isEmpty)) {
      return 'An API key is required for this provider.';
    }
    return null;
  }

  String? _validateBaseUrl(String? value) {
    if (_baseUrlRequired() && (value == null || value.trim().isEmpty)) {
      return 'Base URL is required for this provider.';
    }
    return null;
  }

  String? _validateModel(String? value) {
    if (_modelRequired() && (value == null || value.trim().isEmpty)) {
      return 'A model is required for a custom endpoint.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final systemBottomInset = bottomSystemInset(context);
    final spec = _specFor(_selectedProviderId);
    final limitReached = _limitReachedWatch();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit backend' : 'Add backend'),
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 120 + systemBottomInset),
          children: [
            _buildSectionCard(
              context,
              title: 'Provider',
              subtitle: _isEditing
                  ? 'The provider is fixed once a backend is connected.'
                  : 'Pick which LLM provider this backend talks to.',
              child: _buildProviderPicker(context),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: 'Details',
              subtitle:
                  'A name is optional — it defaults to the provider name.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name (optional)',
                      hintText: 'e.g. Work OpenAI',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  if (_showApiKeyField(spec)) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: _requiresKey(spec) && !_isEditing
                            ? 'API key'
                            : 'API key (optional)',
                        hintText: _isEditing
                            ? (widget.editBackend?.keyHint ??
                                  'Leave blank to keep the current key')
                            : 'sk-...',
                      ),
                      obscureText: true,
                      validator: _validateApiKey,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ],
              ),
            ),
            if (_showBaseUrlField(spec)) ...[
              const SizedBox(height: 12),
              _buildSectionCard(
                context,
                title: 'Endpoint',
                subtitle: _baseUrlRequired()
                    ? 'Base URL is required for this provider.'
                    : 'Override the default API base URL.',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'https://your-endpoint.example.com/v1',
                      ),
                      validator: _validateBaseUrl,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    if (_showLocalRuntimeCaveat()) ...[
                      const SizedBox(height: 10),
                      _buildCaveatBanner(
                        context,
                        "On a phone, \"localhost\" means the phone itself. HyperVault's "
                        'server makes this call, so it needs a LAN IP or a tunnel URL '
                        '(ngrok, Tailscale Funnel) — not localhost.',
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildSectionCard(
              context,
              title: 'Model',
              subtitle: _modelRequired()
                  ? 'Required for a custom endpoint.'
                  : 'Defaults to the provider recommendation when left blank.',
              child: Column(
                children: [
                  TextFormField(
                    controller: _defaultModelController,
                    decoration: InputDecoration(
                      labelText: 'Default model',
                      hintText:
                          providerRawString(spec, 'defaultModel') ?? 'model-id',
                    ),
                    validator: _validateModel,
                    textInputAction: _showEmbeddingField(spec)
                        ? TextInputAction.next
                        : TextInputAction.done,
                  ),
                  if (_showEmbeddingField(spec)) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _embeddingModelController,
                      decoration: InputDecoration(
                        labelText: 'Embedding model (optional)',
                        hintText:
                            providerRawString(spec, 'defaultEmbeddingModel') ??
                            'text-embedding-3-small',
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Semantic recall needs a 1536-dim-compatible embedding model — '
                      "this is verified when the connection is tested.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (limitReached) ...[
              const SizedBox(height: 12),
              _buildCaveatBanner(
                context,
                "You've reached the limit of connected backends. Remove one before "
                'adding another.',
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              _buildErrorBanner(context, _errorText!),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSaveBar(
        context,
        bottomInset: systemBottomInset,
        limitReached: limitReached,
      ),
    );
  }

  Widget _buildProviderPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final providers = _providers;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: providers.map((p) {
        final selected = p.id == _selectedProviderId;
        return ChoiceChip(
          label: Text(providerDisplayName(p)),
          selected: selected,
          onSelected: _isEditing ? null : (_) => _onProviderChanged(p.id),
          selectedColor: colorScheme.primary.withValues(alpha: 0.18),
          labelStyle: TextStyle(
            color: selected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCaveatBanner(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(
    BuildContext context, {
    required double bottomInset,
    required bool limitReached,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disabled = _isSaving || limitReached;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? 4 : 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: disabled ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const HugeIcon(icon: HugeIcons.strokeRoundedFloppyDisk),
            label: Text(
              _isSaving
                  ? 'Testing connection…'
                  : (_isEditing ? 'Save changes' : 'Connect backend'),
            ),
          ),
        ),
      ),
    );
  }
}
