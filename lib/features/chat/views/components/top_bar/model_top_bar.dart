import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:localmind/core/models/enums.dart';
import 'package:localmind/l10n/app_localizations.dart';
import '../../../../servers/data/models/server.dart';
import '../../../../servers/providers/server_providers.dart';
import '../../../../servers/views/components/server_icon_picker.dart';
import '../../../../servers/views/components/server_picker_sheet.dart';

class ModelTopBar extends ConsumerWidget {
  const ModelTopBar({
    super.key,
    required this.selectedModel,
    required this.onModelTap,
  });

  final dynamic selectedModel;
  final VoidCallback onModelTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeServer = ref.watch(activeServerProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final mutedColor = isDark ? Colors.white54 : Colors.black45;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            children: [
              if (activeServer != null) ...[
                InkWell(
                  onTap: () => showServerPickerSheet(context, ref),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ServerGlyph(
                          server: activeServer,
                          connectionStatus: connectionStatus,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.28,
                          ),
                          child: Text(
                            activeServer.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('·', style: TextStyle(color: mutedColor, fontSize: 12)),
                ),
              ],
              Expanded(
                child: InkWell(
                  onTap: onModelTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedModel?.displayName ?? l10n.select_model,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.expand_more, size: 14, color: mutedColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerGlyph extends StatelessWidget {
  const _ServerGlyph({
    required this.server,
    required this.connectionStatus,
    required this.isDark,
  });

  final Server server;
  final ConnectionStatus connectionStatus;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final iconName = server.iconName;
    final serverIcon = iconName != null
        ? (getHugeIconByName(iconName)?.icon ??
              getDefaultServerIcon(server.type.name)?.icon)
        : getDefaultServerIcon(server.type.name)?.icon;

    final statusColor = switch (connectionStatus) {
      ConnectionStatus.connected => Colors.green,
      ConnectionStatus.error => Colors.red,
      ConnectionStatus.checking => Colors.orange,
      ConnectionStatus.disconnected => Colors.grey,
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        HugeIcon(
          icon: serverIcon ?? HugeIcons.strokeRoundedServerStack01,
          size: 14,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
