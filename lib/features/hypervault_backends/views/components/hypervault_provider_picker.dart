import 'package:flutter/material.dart';

import '../../data/models/hv_backend.dart';

/// Provider select for the connect form (T-M10-02), sourced entirely from
/// `capabilities.providers` / `backends.providers` — never a hard-coded
/// provider list, so a server-added provider shows up automatically.
class HyperVaultProviderPicker extends StatelessWidget {
  final List<HvProviderSpec> providers;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  const HyperVaultProviderPicker({
    super.key,
    required this.providers,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final spec in providers)
          ChoiceChip(
            label: Text(spec.label),
            selected: spec.id == selectedId,
            onSelected: (_) => onChanged(spec.id),
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              color: spec.id == selectedId
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            selectedColor: theme.colorScheme.primary,
          ),
      ],
    );
  }
}
