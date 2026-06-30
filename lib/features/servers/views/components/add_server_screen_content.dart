import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:localmind/l10n/app_localizations.dart';
import 'package:localmind/core/components/server/server_icon_picker.dart';
import 'package:localmind/core/constants/app_constants.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/core/providers/service_providers.dart';
import 'package:localmind/core/utils/system_insets.dart';
import 'package:localmind/features/servers/data/models/server.dart';
import 'package:localmind/features/servers/providers/server_providers.dart';
import 'add_server_components.dart';
import 'https_scheme_hint.dart';
import 'server_type_selector.dart';

class AddServerScreenContent extends ConsumerStatefulWidget {
  final Server? editServer;

  const AddServerScreenContent({super.key, this.editServer});

  @override
  ConsumerState<AddServerScreenContent> createState() =>
      _AddServerScreenContentState();
}

class _AddServerScreenContentState extends ConsumerState<AddServerScreenContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _apiKeyController;

  late ServerType _selectedType;
  String? _selectedIconName;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;

  bool get _isEditing => widget.editServer != null;
  bool get _requiresEndpoint => _selectedType != ServerType.openRouter;
  bool get _requiresMandatoryApiKey => _selectedType == ServerType.openRouter;

  @override
  void initState() {
    super.initState();
    final server = widget.editServer;
    _selectedType = server?.type ?? ServerType.lmStudio;
    _selectedIconName = server?.iconName;
    _nameController = TextEditingController(text: server?.name ?? '');
    _hostController = TextEditingController(text: server?.host ?? '');
    _portController = TextEditingController(
      text:
          server?.port.toString() ??
          AppConstants.lmStudioDefaultPort.toString(),
    );
    _apiKeyController = TextEditingController(text: server?.apiKey ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onTypeChanged(ServerType type) {
    setState(() {
      _selectedType = type;
      _testResult = null;

      if (type == ServerType.openRouter) {
        _portController.text = '443';
      } else if (type == ServerType.lmStudio) {
        _portController.text = AppConstants.lmStudioDefaultPort.toString();
      } else if (type == ServerType.openAICompatible) {
        _portController.text = AppConstants.openAICompatibleDefaultPort
            .toString();
      } else if (type == ServerType.ollama) {
        _portController.text = AppConstants.ollamaDefaultPort.toString();
      }
    });
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final apiService = ref.read(serverApiServiceProvider);
    final testServer = _buildServer();

    try {
      final isConnected = await apiService.testConnection(testServer);
      setState(() {
        _testResult = isConnected
            ? AppLocalizations.of(context)!.connection_successful
            : AppLocalizations.of(context)!.connection_failed;
      });
      if (isConnected) {
        invalidateAvailableModelsCache(testServer.id);
      }
    } catch (e) {
      setState(() {
        _testResult = AppLocalizations.of(
          context,
        )!.error_with_message(e.toString());
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Server _buildServer() {
    return Server(
      id:
          widget.editServer?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _selectedType,
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      apiKey: _selectedType == ServerType.openRouter
          ? _apiKeyController.text.trim()
          : (_apiKeyController.text.trim().isNotEmpty
                ? _apiKeyController.text.trim()
                : null),
      isDefault: widget.editServer?.isDefault ?? false,
      createdAt: widget.editServer?.createdAt ?? DateTime.now(),
      lastConnectedAt: widget.editServer?.lastConnectedAt ?? DateTime.now(),
      status: ConnectionStatus.disconnected,
      iconName: _selectedIconName,
    );
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final server = _buildServer();

      if (_isEditing) {
        await ref.read(serversProvider.notifier).updateServer(server);
      } else {
        await ref.read(serversProvider.notifier).addServer(server);
      }
      invalidateAvailableModelsCache(server.id);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? l10n.server_updated : l10n.server_added),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.error_with_message(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateName(String? value) {
    final context = this.context;
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.name_required;
    }
    if (value.trim().length > 50) {
      return l10n.name_length_validation;
    }
    return null;
  }

  String? _validateHost(String? value) {
    if (!_requiresEndpoint) return null;
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.trim().isEmpty) {
      return l10n.host_required;
    }
    final parsed = parseServerAddressInput(value);
    if (parsed == null) {
      return l10n.host_valid;
    }
    return null;
  }

  String? _validatePort(String? value) {
    if (!_requiresEndpoint) return null;
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.trim().isEmpty) {
      return l10n.port_required;
    }
    final port = int.tryParse(value.trim());
    if (port == null || port < 1 || port > 65535) {
      return l10n.port_range;
    }
    return null;
  }

  String? _validateApiKey(String? value) {
    if (_requiresMandatoryApiKey) {
      final l10n = AppLocalizations.of(context)!;
      if (value == null || value.trim().isEmpty) {
        return l10n.api_key_required_openrouter;
      }
      if (!value.trim().startsWith('sk-')) {
        return l10n.api_key_format;
      }
    }
    return null;
  }

  void _showIconPicker() {
    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (context) => ServerIconPicker(
        selectedIconName: _selectedIconName,
        onIconSelected: (iconName) {
          setState(() {
            _selectedIconName = iconName;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final systemBottomInset = bottomSystemInset(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.edit_server : l10n.add_server_title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AddServerFloatingActionBar(
        bottomInset: systemBottomInset,
        isTesting: _isTesting,
        isSaving: _isSaving,
        onTestPressed: _testConnection,
        onSavePressed: _saveServer,
        testLabel: l10n.test_connection,
        testingLabel: l10n.testing,
        saveLabel: _isEditing ? l10n.update_server : l10n.save_server,
        savingLabel: l10n.save,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 120 + systemBottomInset),
          children: [
            AddServerHeaderCard(
              onTap: _showIconPicker,
              title: _isEditing ? l10n.edit_server : l10n.add_server_title,
              description: _requiresEndpoint
                  ? 'Configure a local or self-hosted endpoint, then verify the connection before saving.'
                  : 'Connect through OpenRouter with a valid API key and keep this profile ready for model routing.',
              leadingIcon: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: HugeIcon(
                  icon: getDefaultServerIcon(_selectedType.name)!.icon,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              badges: [
                AddServerInfoPill(
                  icon: Icons.hub_outlined,
                  label: _serverTypeLabel(context),
                ),
                AddServerInfoPill(
                  icon: _requiresMandatoryApiKey ? Icons.key_outlined : Icons.dns,
                  label: _requiresMandatoryApiKey
                      ? l10n.api_key_required
                      : l10n.host_label,
                ),
              ],
            ),
            const SizedBox(height: 14),
            AddServerSectionCard(
              title: l10n.server_type_label,
              subtitle: l10n.server_type_help,
              child: ServerTypeSelector(
                selectedType: _selectedType,
                onChanged: _onTypeChanged,
              ),
            ),
            const SizedBox(height: 12),
            AddServerSectionCard(
              title: l10n.server_identity_title,
              subtitle: l10n.server_identity_desc,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showIconPicker,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        ),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: HugeIcon(
                              icon: _selectedIconName != null
                                  ? (getHugeIconByName(
                                          _selectedIconName,
                                        )?.icon ??
                                        getDefaultServerIcon(
                                          _selectedType.name,
                                        )!.icon)
                                  : getDefaultServerIcon(
                                      _selectedType.name,
                                    )!.icon,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.server_icon_label,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedIconName ?? l10n.default_icon,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.name_label,
                      hintText: l10n.my_server_hint,
                    ),
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            if (_requiresEndpoint) ...[
              const SizedBox(height: 12),
              AddServerSectionCard(
                title: l10n.server_connection_title,
                subtitle: l10n.server_connection_desc,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _hostController,
                      decoration: InputDecoration(
                        labelText: l10n.host_label,
                        hintText: '192.168.1.100',
                      ),
                      validator: _validateHost,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                    ),
                    HttpsSchemeHint(controller: _hostController),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: l10n.port_label,
                        hintText: _selectedType == ServerType.lmStudio
                            ? AppConstants.lmStudioDefaultPort.toString()
                            : AppConstants.ollamaDefaultPort.toString(),
                      ),
                      validator: _validatePort,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            AddServerSectionCard(
              title: l10n.server_authentication_title,
              subtitle: _requiresMandatoryApiKey
                  ? l10n.server_authentication_required_desc
                  : l10n.server_authentication_optional_desc,
              child: TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: _requiresMandatoryApiKey
                      ? l10n.api_key_required
                      : l10n.api_key_optional,
                  hintText: _requiresMandatoryApiKey
                      ? l10n.api_key_hint_openrouter
                      : l10n.api_key_hint_generic,
                ),
                validator: _validateApiKey,
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              AddServerTestResultBanner(
                message: _testResult!,
                success: _testResult!.contains(
                  l10n.connection_successful.split('!')[0],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _serverTypeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_selectedType) {
      ServerType.lmStudio => l10n.server_type_lm_studio,
      ServerType.openAICompatible => l10n.server_type_openai_display,
      ServerType.ollama => l10n.server_type_ollama,
      ServerType.openRouter => l10n.server_type_openrouter,
      ServerType.onDevice => l10n.server_type_on_device_display,
    };
  }
}
