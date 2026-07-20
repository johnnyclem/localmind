import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session in the platform Keychain/Keystore instead
/// of supabase_flutter's SharedPreferences-backed default, matching the
/// mobile spec's "access + refresh JWT in expo-secure-store" requirement
/// (HyperVault docs/mobile/prd/02-auth-onboarding.md, T-M2-01).
class HvSecureLocalStorage extends LocalStorage {
  const HvSecureLocalStorage();

  static const _storage = FlutterSecureStorage();
  static const _key = 'hypervault_supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return (await _storage.read(key: _key)) != null;
  }

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
