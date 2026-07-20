import '../../../hypervault/data/hypervault_api_client.dart';
import 'models/hv_import_result.dart';

/// Typed wrapper over `POST /api/import` (spec
/// docs/mobile/prd/12-import-history.md). Unlike `/api/memories/import`, this
/// endpoint takes plain JSON `{data, platform?, title?}` — no multipart —
/// so both the file-pick and paste paths just supply a string.
class HvImportService {
  final HyperVaultApiClient _client;

  const HvImportService(this._client);

  Future<HvImportResult> import({
    required String data,
    String? platform,
    String? title,
  }) async {
    final json = await _client.post(
      '/api/import',
      body: {
        'data': data,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      },
    );
    return HvImportResult.fromJson(json);
  }
}
