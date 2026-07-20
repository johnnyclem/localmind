import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/artifact_identity_cache.dart';
import 'hypervault_providers.dart';

/// Shared slug<->id identity cache for vault artifacts — see
/// [ArtifactIdentityCache] doc for the bug this exists to work around. Lives
/// under `core/providers` (rather than `vault_graph` or `connections`)
/// because both features need to read and write it without creating a
/// dependency of one feature on the other.
final artifactIdentityCacheProvider = Provider<ArtifactIdentityCache>((ref) {
  return ArtifactIdentityCache(ref.watch(hyperVaultCacheProvider));
});
