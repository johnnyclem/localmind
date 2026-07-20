import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/hypervault_providers.dart';
import '../data/connections_api_service.dart';
import '../data/shares_api_service.dart';

final connectionsApiServiceProvider = Provider<ConnectionsApiService>((ref) {
  return ConnectionsApiService(ref.watch(hypervaultClientProvider));
});

final sharesApiServiceProvider = Provider<SharesApiService>((ref) {
  return SharesApiService(ref.watch(hypervaultClientProvider));
});
