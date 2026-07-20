/// Normalized error from a HyperVault REST call. Every HyperVault API error
/// body is `{ error: string }` (see api-contract.md) — this surfaces it
/// verbatim alongside the HTTP status so callers can branch on status while
/// still showing the server's own message.
class HvApiError implements Exception {
  final int? status;
  final String error;

  const HvApiError({this.status, required this.error});

  bool get isUnauthorized => status == 401;
  bool get isWaitlisted => status == 403;
  bool get isRateLimited => status == 429;
  bool get isServiceUnavailable => status == 503;

  @override
  String toString() => error;
}
