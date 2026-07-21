import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../backends/data/models/backend.dart';

/// A select listing connected backends (`name — default_model`) — T-M8-06.
/// Reuses the already-built `lib/features/backends/` `Backend` model and
/// `backendsProvider`; this widget only renders the picker itself, the
/// caller supplies the list + selection.
///
/// Optionally surfaces a synthetic "On-device" entry ([onDeviceBackendId])
/// alongside the connected backends (M9 on-device inference epic) — gated by
/// the caller on `capabilities.features.onDeviceInference`. [onDeviceReady]
/// only affects the label/hint shown; whether tapping it starts a chat or
/// deep-links to the on-device model manager is the caller's decision (via
/// [onChanged]), since this widget has no navigation context of its own.
class HvBackendPicker extends StatelessWidget {
  const HvBackendPicker({
    super.key,
    required this.backends,
    required this.selectedId,
    required this.onChanged,
    this.showOnDevice = false,
    this.onDeviceReady = false,
  });

  /// Synthetic id used for the on-device entry — never a real `Backend.id`.
  static const String onDeviceBackendId = '__on_device__';

  final List<Backend> backends;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool showOnDevice;
  final bool onDeviceReady;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validIds = <String>{
      ...backends.map((b) => b.id),
      if (showOnDevice) onDeviceBackendId,
    };
    final validSelection = validIds.contains(selectedId) ? selectedId : null;
    final isOnDeviceSelected = validSelection == onDeviceBackendId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue: validSelection,
          isExpanded: true,
          isDense: true,
          decoration: const InputDecoration(
            labelText: 'Backend',
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            ...backends.map(
              (b) => DropdownMenuItem<String>(
                value: b.id,
                child: Text(
                  (b.defaultModel?.isNotEmpty ?? false)
                      ? '${b.name} — ${b.defaultModel}'
                      : b.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (showOnDevice)
              DropdownMenuItem<String>(
                value: onDeviceBackendId,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAiChip,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        onDeviceReady
                            ? 'On-device'
                            : 'On-device — set up a model',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
        if (isOnDeviceSelected)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedShield01,
                  size: 12,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Runs on this device — private, offline-capable',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
