/// Decouples the HyperVault Dio client from the Supabase auth module.
///
/// The network layer (M1) needs to attach a Bearer token and react to 401s;
/// the auth module (M2) is what owns the Supabase session and knows how to
/// refresh it. Both sides depend on this single leaf provider instead of on
/// each other, avoiding a circular provider dependency.
class AuthTokenHolder {
  String? _token;

  /// Set by the auth module once a session exists; cleared on sign-out.
  Future<String?> Function()? onUnauthorized;

  String? get token => _token;

  void set(String? value) {
    _token = value;
  }

  void clear() {
    _token = null;
  }
}
