import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind/core/providers/model_picker/model_picker_providers.dart';
import 'package:localmind/l10n/app_localizations.dart';

class ModelSearchField extends ConsumerWidget {
  const ModelSearchField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(modelSearchQueryProvider);

    return TextField(
      decoration: InputDecoration(
        hintText: l10n.search_models_hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () =>
                    ref.read(modelSearchQueryProvider.notifier).clear(),
              )
            : null,
      ),
      onChanged: (q) =>
          ref.read(modelSearchQueryProvider.notifier).setQuery(q),
    );
  }
}
