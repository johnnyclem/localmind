import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session JWT in the platform Keychain/Keystore
/// instead of `SharedPreferences` (spec §8: "Token storage: access + refresh
/// JWT in `expo-secure-store`"). Reuses the same `flutter_secure_storage`
/// package the cloud-sync feature already depends on for S3 credentials.
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage;
  final String _key;

  SecureLocalStorage({
    FlutterSecureStorage? storage,
    String key = 'hypervault.session.v1',
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _key = key;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await _storage.read(key: _key)) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}

/// Secure-storage-backed PKCE code-verifier store, used during the OAuth
/// exchange. Short-lived (cleared once the code exchange completes) but
/// still shouldn't sit in plaintext prefs.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  final FlutterSecureStorage _storage;

  SecureGotrueAsyncStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  String _prefixed(String key) => 'hypervault.pkce.$key';

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: _prefixed(key));

  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: _prefixed(key));

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: _prefixed(key), value: value);
}
