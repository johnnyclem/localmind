import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hypervault/data/models/hv_api_error.dart';
import '../providers/hypervault_polish_providers.dart';
import 'components/hv_theme_swatch_card.dart';

/// Renders a swatch per `capabilities.themes` entry using
/// [HvThemeMapper]. Preview-only — no theme is applied to the live app from
/// here (lib/app.dart is out of scope for this feature); see
/// integrationNotes for how a follow-up would let a user actually pick one.
class HvThemeGalleryScreen extends ConsumerWidget {
  const HvThemeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairs = ref.watch(hyperVaultThemePairsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HyperVault Themes')),
      body: SafeArea(
        child: pairs.when(
          data: (list) {
            if (list.isEmpty) {
              return const Center(child: Text('No themes available.'));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) =>
                  HvThemeSwatchCard(pair: list[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                e is HvApiError ? e.error : 'Could not load theme catalog.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
