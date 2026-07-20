import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/logger/app_logger.dart';
import '../../../core/models/hypervault_capabilities.dart';
import '../../../core/network/hypervault_api_exception.dart';
import '../../../core/providers/hypervault_providers.dart';
import '../../../core/storage/secure_supabase_storage.dart';
import '../data/models/auth_gate_status.dart';

class HyperVaultAuthState {
  final AuthGateStatus status;
  final sb.Session? session;
  final String? errorMessage;

  const HyperVaultAuthState({
    this.status = AuthGateStatus.loading,
    this.session,
    this.errorMessage,
  });

  sb.User? get user => session?.user;
  String? get email => session?.user.email;

  HyperVaultAuthState copyWith({
    AuthGateStatus? status,
    sb.Session? session,
    bool clearSession = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HyperVaultAuthState(
      status: status ?? this.status,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Owns the Supabase device session lifecycle: lazy client init (once
/// capabilities has the project URL/anon key), Google OAuth via deep link,
/// silent refresh, the invite/waitlist gate, and sign-out. Every other
/// feature reads [authProvider] for `status`/`user`; the HyperVault SDK
/// (M1) reads only the bearer token via [authTokenHolderProvider], which
/// this notifier keeps in sync.
class AuthNotifier extends Notifier<HyperVaultAuthState> {
  StreamSubscription<sb.AuthState>? _subscription;
  bool _clientReady = false;

  @override
  HyperVaultAuthState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    Future.microtask(_bootstrap);
    return const HyperVaultAuthState();
  }

  Future<void> _bootstrap() async {
    try {
      final capabilities = await ref.read(capabilitiesProvider.future);
      await _ensureClientInitialized(capabilities);
      ref.read(authTokenHolderProvider).onUnauthorized = _refreshAccessToken;

      _subscription = sb.Supabase.instance.client.auth.onAuthStateChange.listen((
        event,
      ) {
        _onAuthEvent(event.session);
      });

      final currentSession = sb.Supabase.instance.client.auth.currentSession;
      await _onAuthEvent(currentSession);
    } catch (e) {
      Log.error('[auth] bootstrap failed: $e');
      state = state.copyWith(
        status: AuthGateStatus.unauthenticated,
        errorMessage: 'Could not reach HyperVault. Check your connection and retry.',
      );
    }
  }

  Future<void> _ensureClientInitialized(
    HyperVaultCapabilities capabilities,
  ) async {
    if (_clientReady) return;
    final url = capabilities.auth.supabaseUrl;
    final anonKey = capabilities.auth.supabaseAnonKey;
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError('HyperVault capabilities did not include Supabase auth config.');
    }
    await sb.Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      authOptions: sb.FlutterAuthClientOptions(
        authFlowType: sb.AuthFlowType.pkce,
        localStorage: SecureLocalStorage(),
        pkceAsyncStorage: SecureGotrueAsyncStorage(),
      ),
    );
    _clientReady = true;
  }

  Future<void> _onAuthEvent(sb.Session? session) async {
    final tokenHolder = ref.read(authTokenHolderProvider);
    tokenHolder.set(session?.accessToken);

    if (session == null) {
      state = const HyperVaultAuthState(status: AuthGateStatus.unauthenticated);
      return;
    }

    state = HyperVaultAuthState(status: AuthGateStatus.loading, session: session);
    try {
      final gate = await _resolveGate(session);
      state = HyperVaultAuthState(status: gate, session: session);
    } catch (e) {
      // Unlike the old direct `account_access` read, this probe can tell
      // "actually waitlisted" (403, handled inside _resolveGate) apart from
      // a genuine network/server hiccup — so a hiccup here no longer fails
      // open to approved. Surface it and let the user retry from sign-in.
      Log.error('[auth] gate probe failed: $e');
      state = HyperVaultAuthState(
        status: AuthGateStatus.unauthenticated,
        errorMessage: 'Could not verify access. Check your connection and try again.',
      );
      return;
    }

    // Bearer is now attached; pull the enriched capabilities.user block.
    unawaited(ref.read(capabilitiesProvider.notifier).refresh());
  }

  /// Resolves the invite/waitlist gate by probing a real
  /// `resolveApiIdentity`-gated HyperVault route (`GET /api/artifacts`)
  /// instead of reading the `account_access` table directly. The server
  /// enforces the gate on every request regardless of what the client
  /// believes, so a 403 here is ground truth for "waitlisted" — and an admin
  /// (who bypasses the waitlist server-side) simply gets a 200 back, so they
  /// come out "approved" with zero extra client-side admin logic.
  Future<AuthGateStatus> _resolveGate(sb.Session session) async {
    final client = ref.read(hypervaultClientProvider);
    try {
      await client.get<dynamic>('/api/artifacts');
      return AuthGateStatus.approved;
    } on HyperVaultApiException catch (e) {
      if (e.isForbidden) return AuthGateStatus.waitlisted;
      rethrow;
    }
  }

  Future<String?> _refreshAccessToken() async {
    try {
      final response = await sb.Supabase.instance.client.auth.refreshSession();
      final token = response.session?.accessToken;
      ref.read(authTokenHolderProvider).set(token);
      return token;
    } catch (e) {
      Log.warning('[auth] token refresh failed: $e');
      await signOut();
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await sb.Supabase.instance.client.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: 'hypervault://auth/callback',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Sign-in failed. Please try again.',
      );
    }
  }

  Future<void> redeemInviteCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;
    try {
      final result = await sb.Supabase.instance.client.rpc(
        'redeem_invite_code',
        params: {'p_code': normalized},
      );
      final resultString = result is String ? result : result?.toString();
      if (resultString == 'ok' || resultString == 'already_approved') {
        final session = sb.Supabase.instance.client.auth.currentSession;
        if (session != null) {
          try {
            final gate = await _resolveGate(session);
            state = HyperVaultAuthState(status: gate, session: session);
          } catch (e) {
            Log.error('[auth] post-redeem gate probe failed: $e');
            state = state.copyWith(
              errorMessage:
                  'Code redeemed, but could not verify access yet. Try again in a moment.',
            );
          }
        }
      } else {
        state = state.copyWith(
          errorMessage: resultString ?? 'That invite code did not work. Double-check it and try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'That invite code did not work. Double-check it and try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> signOut() async {
    try {
      await sb.Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Local state is cleared regardless below.
    }
    ref.read(authTokenHolderProvider).clear();
    await ref.read(hyperVaultCacheProvider).clearForUser(
      state.user?.id ?? '',
    );
    state = const HyperVaultAuthState(status: AuthGateStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, HyperVaultAuthState>(
  AuthNotifier.new,
);
