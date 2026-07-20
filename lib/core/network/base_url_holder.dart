import '../constants/app_constants.dart';

/// Mutable holder for the canonical HyperVault `app_url`. Starts at the
/// hardcoded default so the very first `GET /api/capabilities` call has
/// somewhere to go, then the capabilities provider updates it once the real
/// value loads (spec §8: the app always targets the canonical `app_url`,
/// never host-based routing).
class BaseUrlHolder {
  String _baseUrl = AppConstants.hypervaultDefaultBaseUrl;

  String get baseUrl => _baseUrl;

  void set(String value) {
    if (value.startsWith('https://')) {
      _baseUrl = value;
    }
  }
}
