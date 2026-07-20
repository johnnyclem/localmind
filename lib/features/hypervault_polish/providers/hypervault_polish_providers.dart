import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../hypervault/providers/hypervault_providers.dart';
import '../data/hv_theme_mapper.dart';
import '../data/models/hv_theme_pair.dart';

/// The connected deployment's theme catalog (`capabilities.themes`) mapped
/// into [HvThemePair]s for the preview gallery. Not wired into
/// [themeModeProvider] (lib/core/providers/app_providers.dart) — see
/// integrationNotes for the follow-up that would do that.
final hyperVaultThemePairsProvider = Provider<AsyncValue<List<HvThemePair>>>((
  ref,
) {
  final capabilities = ref.watch(hyperVaultCapabilitiesProvider);
  return capabilities.whenData(
    (c) => HvThemeMapper.allFor(c.themes),
  );
});
