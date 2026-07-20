import '../constants/app_constants.dart';

/// Mutable holder for the canonical HyperVault `app_url`. Starts at the
/// hardcoded default so the very first `GET /api/capabilities` call has
/// somewhere to go, then the capabilities provider updates it once the real
/// value loads (spec §8: the app always targets the canonical `app_url`,
/// never host-based routing).
///
/// A user-supplied [override] (self-hosted deployments; see
/// `customBaseUrlProvider`) takes precedence over the capabilities-resolved
/// value for as long as it is set, so the very first bootstrap request goes
/// to the user's deployment instead of the hosted default.
class BaseUrlHolder {
  String _baseUrl = AppConstants.hypervaultDefaultBaseUrl;
  String? _override;

  String get baseUrl => _override ?? _baseUrl;

  /// Called by [CapabilitiesNotifier] once `GET /api/capabilities` resolves.
  void set(String value) {
    if (value.startsWith('https://')) {
      _baseUrl = value;
    }
  }

  /// Called with the user's self-hosted deployment URL (or `null`/empty to
  /// clear it and fall back to the hosted default / last resolved app_url).
  void setOverride(String? value) {
    if (value == null || value.trim().isEmpty) {
      _override = null;
      return;
    }
    final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.startsWith('https://') || normalized.startsWith('http://')) {
      _override = normalized;
    }
  }
}
