import 'package:dio/dio.dart';

import 'models/hv_capabilities.dart';
import 'models/hv_api_error.dart';

/// Fetches `GET /api/capabilities` — the one unauthenticated call a
/// HyperVault client needs to bootstrap itself (base URL is already known;
/// this describes everything else: auth config, feature flags, limits,
/// provider registry, vanity domains, theme catalog). Passing [accessToken]
/// enriches the response with a `user` block.
class HyperVaultCapabilitiesService {
  final Dio _dio;

  HyperVaultCapabilitiesService(this._dio);

  Future<HvCapabilities> fetch(String baseUrl, {String? accessToken}) async {
    final normalized = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$normalized/api/capabilities',
        options: Options(
          headers: {
            if (accessToken != null && accessToken.isNotEmpty)
              'Authorization': 'Bearer $accessToken',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = response.data;
      if (response.statusCode != 200 || data == null) {
        throw HvApiError(
          status: response.statusCode,
          error: (data?['error'] as String?) ?? 'Failed to load capabilities',
        );
      }
      return HvCapabilities.fromJson(data);
    } on DioException catch (e) {
      throw HvApiError(
        status: e.response?.statusCode,
        error: e.message ?? 'Could not reach $normalized',
      );
    }
  }
}
