/// Normalized error thrown by [HyperVaultClient] for every non-2xx response
/// or transport failure. HyperVault always responds with `{ error: string }`
/// on failure — [message] is that string verbatim, safe to show in a toast.
class HyperVaultApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;

  const HyperVaultApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isRateLimited => statusCode == 429;
  bool get isServiceUnavailable => statusCode == 503;
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;
}
