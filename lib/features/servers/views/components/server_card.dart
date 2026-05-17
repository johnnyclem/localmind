import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../../../core/models/enums.dart';
import '../../data/models/server.dart';
import 'connection_status_indicator.dart';
import 'server_icon_picker.dart';

class ServerCard extends StatelessWidget {
  final Server server;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const ServerCard({
    super.key,
    required this.server,
    this.isActive = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
  });

  HugeIconData? get _serverIconData {
    if (server.iconName != null) {
      return getHugeIconByName(server.iconName);
    }
    return getDefaultServerIcon(server.type.name);
  }

  String _serverTypeName(AppLocalizations l10n) {
    switch (server.type) {
      case ServerType.lmStudio:
        return l10n.server_type_lm_studio_display;
      case ServerType.openAICompatible:
        return l10n.server_type_openai_display;
      case ServerType.ollama:
        return l10n.server_type_ollama_display;
      case ServerType.openRouter:
        return l10n.server_type_openrouter_display;
      case ServerType.onDevice:
        return l10n.server_type_on_device_display;
    }
  }

  String _serverAddress(AppLocalizations l10n) {
    if (server.type == ServerType.openRouter) {
      return l10n.server_address_openrouter;
    }
    if (server.type == ServerType.onDevice) {
      return l10n.server_address_on_device;
    }
    return l10n.server_address_format(server.host, server.port.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final activeGreen = const Color(0xFF22C55E);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isActive ? activeGreen.withValues(alpha: 0.08) : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? activeGreen.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.1),
          width: isActive ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (isActive)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: activeGreen,
                    borderRadius: const BorderRadiusDirectional.only(
                      topEnd: Radius.circular(4),
                      bottomEnd: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeGreen.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? activeGreen.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: _serverIconData != null
                        ? HugeIcon(
                            icon: _serverIconData!.icon,
                            size: 24,
                            color: isActive
                                ? activeGreen
                                : theme.colorScheme.onSurfaceVariant,
                          )
                        : Icon(
                            Icons.dns,
                            color: isActive
                                ? activeGreen
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                server.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsetsDirectional.only(end: 4),
                                decoration: BoxDecoration(
                                  color: activeGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.active,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (server.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? activeGreen.withValues(alpha: 0.05)
                                      : theme.colorScheme.outline.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isActive
                                        ? activeGreen.withValues(alpha: 0.3)
                                        : theme.colorScheme.outline,
                                  ),
                                ),
                                child: Text(
                                  l10n.default_badge,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isActive
                                        ? activeGreen
                                        : theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _serverTypeName(l10n),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Text('\u2022', style: theme.textTheme.bodySmall),
                            const SizedBox(width: 8),
                            Text(
                              _serverAddress(l10n),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConnectionStatusIndicator(status: server.status),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'setDefault':
                          onSetDefault?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.edit),
                          ],
                        ),
                      ),
                      if (!server.isDefault)
                        PopupMenuItem(
                          value: 'setDefault',
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.set_as_default),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
