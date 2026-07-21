import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../data/models/vault_connection.dart';
import '../data/vault_graph_api_service.dart';

final vaultGraphApiServiceProvider = Provider<VaultGraphApiService>((ref) {
  return VaultGraphApiService(ref.watch(hypervaultClientProvider));
});

/// Edges for the Vault Graph (mobile PRD M4). Edges are supplementary to the
/// node list (already owned by `vaultListProvider`) — if `/api/connections`
/// fails, the graph should still render nodes-only rather than blocking the
/// whole screen, so failures here degrade to an empty edge list instead of
/// surfacing an [AsyncError].
final vaultConnectionsProvider = FutureProvider<List<VaultConnection>>((
  ref,
) async {
  final api = ref.watch(vaultGraphApiServiceProvider);
  try {
    return await api.fetchConnections();
  } on HyperVaultApiException catch (e) {
    Log.warning('[vault_graph] connections fetch failed: ${e.message}');
    return const <VaultConnection>[];
  } catch (e) {
    Log.warning('[vault_graph] connections fetch failed: $e');
    return const <VaultConnection>[];
  }
});
