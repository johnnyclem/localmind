import 'package:dio/dio.dart';

import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/network/hypervault_client.dart';
import 'models/import_history_result.dart';

/// Wraps `POST /api/import` (mobile PRD M12).
///
/// This call can take up to 60s server-side (`maxDuration 60` while it
/// reconstructs conversations/messages), which is longer than
/// [HyperVaultClient]'s default 30s `receiveTimeout`. Rather than change that
/// shared default for every other call, this service reaches into the
/// client's public `dio` field directly for this one request and applies a
/// longer timeout, replicating [HyperVaultClient]'s `{ error }` normalization
/// locally since bypassing `post<T>` also bypasses its error handling.
class ImportHistoryApiService {
  final HyperVaultClient _client;

  ImportHistoryApiService(this._client);

  Future<ImportHistoryResult> importHistory({
    required String data,
    String? platform,
    String? title,
  }) async {
    final payload = <String, dynamic>{'data': data};
    if (platform != null && platform.isNotEmpty) {
      payload['platform'] = platform;
    }
    if (title != null && title.trim().isNotEmpty) {
      payload['title'] = title.trim();
    }

    late final Response<dynamic> response;
    try {
      response = await _client.dio.request<dynamic>(
        '/api/import',
        data: payload,
        options: Options(
          method: 'POST',
          receiveTimeout: const Duration(seconds: 65),
        ),
      );
    } on DioException catch (e) {
      throw HyperVaultApiException(
        message: e.message ?? 'Network error contacting HyperVault.',
      );
    }

    final status = response.statusCode ?? 0;
    final body = response.data;
    if (status >= 200 && status < 300) {
      if (body is Map<String, dynamic>) {
        return ImportHistoryResult.fromJson(body);
      }
      throw const HyperVaultApiException(
        message: 'Unexpected response from server.',
      );
    }

    throw _errorFor(status, body);
  }

  HyperVaultApiException _errorFor(int status, dynamic body) {
    String message = 'Request failed ($status).';
    String? code;
    if (body is Map<String, dynamic>) {
      final err = body['error'];
      if (err is String && err.isNotEmpty) message = err;
      final c = body['code'];
      if (c is String) code = c;
    } else if (body is String && body.isNotEmpty) {
      message = body;
    }
    return HyperVaultApiException(
      statusCode: status,
      message: message,
      code: code,
    );
  }
}
