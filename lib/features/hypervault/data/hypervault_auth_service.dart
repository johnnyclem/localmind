import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logger/app_logger.dart';
import 'hv_secure_local_storage.dart';
import 'models/hv_capabilities.dart';

/// The `hypervault://` deep link the Supabase project's redirect allow-list
/// must include (HyperVault docs/mobile/prd/02-auth-onboarding.md, T-M2-02 —
/// an external ops task on the HyperVault deployment, not something this app
/// can configure itself).
const String hyperVaultAuthCallbackUrl = 'hypervault://auth/callback';

/// Wraps the Supabase client used for HyperVault sign-in: PKCE Google OAuth
/// via a deep link, session persisted in the Keychain/Keystore (see
/// [HvSecureLocalStorage]), and silent refresh. One instance per app run;
/// [initialize] is idempotent so multiple callers (e.g. providers rebuilding)
/// are safe.
class HyperVaultAuthService {
  bool _initialized = false;
  String? _initializedForUrl;

  bool get isInitialized => _initialized;

  /// Initializes the underlying Supabase client from the deployment's
  /// bootstrapped capabilities. Safe to call more than once; re-initializes
  /// only if the configured project URL actually changed (e.g. the user
  /// switched to a self-hosted HyperVault deployment).
  Future<void> initialize(HvCapabilities capabilities) async {
    final url = capabilities.auth.supabaseUrl;
    final anonKey = capabilities.auth.supabaseAnonKey;
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError(
        'HyperVault deployment did not return Supabase auth config',
      );
    }
    if (_initialized && _initializedForUrl == url) return;

    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: HvSecureLocalStorage(),
        autoRefreshToken: true,
      ),
      debug: false,
    );
    _initialized = true;
    _initializedForUrl = url;
    Log.info('HyperVault auth initialized for $url');
  }

  GoTrueClient get _auth => Supabase.instance.client.auth;

  Session? get currentSession => _initialized ? _auth.currentSession : null;

  User? get currentUser => _initialized ? _auth.currentUser : null;

  String? get currentAccessToken => currentSession?.accessToken;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<bool> signInWithGoogle() {
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: hyperVaultAuthCallbackUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _auth.signOut();
}
