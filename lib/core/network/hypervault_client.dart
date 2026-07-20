import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import 'auth_token_holder.dart';
import 'hypervault_api_exception.dart';

/// Typed transport for the HyperVault REST API.
///
/// Every feature's API service (VaultApiService, MemoryApiService, ...)
/// should be a thin wrapper around one of these — mirroring the existing
/// `ServerApiService` pattern — rather than talking to Dio directly. This
/// class owns exactly what T-M1-03 specifies: base URL, Bearer injection,
/// retry/backoff, and `{ error }` normalization. It knows nothing about any
/// single feature's response shapes.
class HyperVaultClient {
  final Dio dio;

  HyperVaultClient(this.dio);

  /// Builds a [Dio] instance wired with auth injection, retry/backoff, and
  /// error normalization. [baseUrlProvider] is read on every request so the
  /// client can adopt `capabilities.app_url` once it loads without needing
  /// to be recreated.
  static Dio buildDio({
    required String Function() baseUrlProvider,
    required AuthTokenHolder tokenHolder,
    void Function(String method, String path, int? status, Duration elapsed)?
    onRequestComplete,
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
        validateStatus: (_) => true, // handled by the error interceptor below
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final base = baseUrlProvider();
          if (!options.path.startsWith('http')) {
            options.baseUrl = base;
          }
          final token = tokenHolder.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.extra['__startedAt'] = DateTime.now();
          handler.next(options);
        },
        onResponse: (response, handler) async {
          final status = response.statusCode ?? 0;
          _emitTelemetry(response.requestOptions, status, onRequestComplete);

          if (status == 401 && tokenHolder.onUnauthorized != null) {
            final retried = response.requestOptions.extra['__retried401'] == true;
            if (!retried) {
              final freshToken = await tokenHolder.onUnauthorized!.call();
              if (freshToken != null && freshToken.isNotEmpty) {
                final retryOptions = response.requestOptions
                  ..extra['__retried401'] = true;
                try {
                  final retryResponse = await dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                } catch (_) {
                  // fall through to normal error handling below
                }
              }
            }
          }

          if (status >= 500 || status == 429) {
            final retryCount =
                (response.requestOptions.extra['__retryCount'] as int?) ?? 0;
            final method = response.requestOptions.method.toUpperCase();
            final idempotent = method == 'GET' || method == 'DELETE';
            if (idempotent && retryCount < 3) {
              final delayMs =
                  (pow(2, retryCount) * 300).toInt() +
                  Random().nextInt(200);
              await Future<void>.delayed(Duration(milliseconds: delayMs));
              final retryOptions = response.requestOptions
                ..extra['__retryCount'] = retryCount + 1;
              try {
                final retryResponse = await dio.fetch(retryOptions);
                return handler.resolve(retryResponse);
              } catch (_) {
                // fall through
              }
            }
          }

          handler.next(response);
        },
        onError: (error, handler) {
          _emitTelemetry(
            error.requestOptions,
            error.response?.statusCode,
            onRequestComplete,
          );
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static void _emitTelemetry(
    RequestOptions options,
    int? status,
    void Function(String, String, int?, Duration)? onRequestComplete,
  ) {
    final startedAt = options.extra['__startedAt'] as DateTime?;
    final elapsed = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);
    onRequestComplete?.call(options.method, options.path, status, elapsed);
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send<T>('GET', path, query: query);

  Future<T> post<T>(String path, {Object? data, Map<String, dynamic>? query}) =>
      _send<T>('POST', path, data: data, query: query);

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) => _send<T>('PATCH', path, data: data, query: query);

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) => _send<T>('DELETE', path, data: data, query: query);

  Future<T> _send<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    late final Response<dynamic> response;
    try {
      response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      throw HyperVaultApiException(
        message: e.message ?? 'Network error contacting HyperVault.',
      );
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return response.data as T;
    }

    throw _errorFor(status, response.data);
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
    return HyperVaultApiException(statusCode: status, message: message, code: code);
  }
}
