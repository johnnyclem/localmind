import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../data/models/server.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/utils/system_insets.dart';
import '../providers/server_providers.dart';
import 'components/server_icon_picker.dart';
import 'components/server_type_selector.dart';

class AddServerScreen extends ConsumerStatefulWidget {
  final Server? editServer;

  const AddServerScreen({super.key, this.editServer});

  @override
  ConsumerState<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends ConsumerState<AddServerScreen> {
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
    if (_selectedType == ServerType.openRouter) return null;
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.trim().isEmpty) {
      return l10n.host_required;
    }
    // Clean any protocol prefixes (http:// or https://) for validation
    final cleaned = value.trim().replaceFirst(RegExp(r'^https?://'), '');
    final hostPattern = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-\.]*[a-zA-Z0-9])?$');
    if (!hostPattern.hasMatch(cleaned)) {
      return l10n.host_valid;
    }
    return null;
  }

  String? _validatePort(String? value) {
    if (_selectedType == ServerType.openRouter) return null;
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
    if (_selectedType == ServerType.openRouter) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.edit_server : l10n.add_server_title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + systemBottomInset),
          children: [
            Text(l10n.server_type_label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ServerTypeSelector(
              selectedType: _selectedType,
              onChanged: _onTypeChanged,
            ),
            const SizedBox(height: 24),

            Text(l10n.server_icon_label, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showIconPicker,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: HugeIcon(
                        icon: _selectedIconName != null
                            ? (getHugeIconByName(_selectedIconName)?.icon ??
                                  getDefaultServerIcon(
                                    _selectedType.name,
                                  )!.icon)
                            : getDefaultServerIcon(_selectedType.name)!.icon,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedIconName ?? l10n.default_icon,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name_label,
                hintText: l10n.my_server_hint,
              ),
              validator: _validateName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            if (_selectedType != ServerType.openRouter) ...[
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
              const SizedBox(height: 16),

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
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: _selectedType == ServerType.openRouter
                    ? l10n.api_key_required
                    : l10n.api_key_optional,
                hintText: _selectedType == ServerType.openRouter
                    ? l10n.api_key_hint_openrouter
                    : l10n.api_key_hint_generic,
              ),
              validator: _validateApiKey,
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            if (_testResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _testResult!.contains(
                        l10n.connection_successful.split('!')[0],
                      )
                      ? Colors.green.withAlpha(25)
                      : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _testResult!.contains(
                          l10n.connection_successful.split('!')[0],
                        )
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult!.contains(
                            l10n.connection_successful.split('!')[0],
                          )
                          ? Icons.check_circle
                          : Icons.error,
                      color:
                          _testResult!.contains(
                            l10n.connection_successful.split('!')[0],
                          )
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color:
                              _testResult!.contains(
                                l10n.connection_successful.split('!')[0],
                              )
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check),
              label: Text(_isTesting ? l10n.testing : l10n.test_connection),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _saveServer,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? l10n.update_server : l10n.save_server),
            ),
          ],
        ),
      ),
    );
  }
}
