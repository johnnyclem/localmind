import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../hypervault/providers/hypervault_providers.dart';
import '../data/hv_import_service.dart';

final hvImportServiceProvider = Provider<HvImportService>((ref) {
  return HvImportService(ref.read(hyperVaultApiClientProvider));
});
