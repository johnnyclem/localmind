import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/storage_providers.dart';
import '../../servers/data/models/server.dart';
import '../../servers/providers/server_providers.dart';
import '../data/hypervault_api_client.dart';
import '../data/hypervault_auth_service.dart';
import '../data/hypervault_capabilities_service.dart';
import '../data/hypervault_conversation_link_service.dart';
import '../data/models/hv_api_error.dart';
import '../data/models/hv_capabilities.dart';

const _baseUrlPrefsKey = 'hypervaultBaseUrl';

/// The HyperVault deployment origin this app talks to. Defaults to the
/// hosted deployment; self-hosters can repoint it from the sign-in screen.
final hyperVaultBaseUrlProvider =
    NotifierProvider<HyperVaultBaseUrlNotifier, String>(
      HyperVaultBaseUrlNotifier.new,
    );

class HyperVaultBaseUrlNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(_baseUrlPrefsKey) ??
        AppConstants.hyperVaultDefaultBaseUrl;
  }

  void setBaseUrl(String url) {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.isEmpty || normalized == state) return;
    ref.read(sharedPreferencesProvider).setString(_baseUrlPrefsKey, normalized);
    state = normalized;
  }
}

final hyperVaultAuthServiceProvider = Provider<HyperVaultAuthService>((ref) {
  return HyperVaultAuthService();
});

final _hyperVaultBootstrapDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
});

final hyperVaultCapabilitiesServiceProvider =
    Provider<HyperVaultCapabilitiesService>((ref) {
      return HyperVaultCapabilitiesService(
        ref.read(_hyperVaultBootstrapDioProvider),
      );
    });

/// Bootstraps the connected HyperVault deployment: fetches
/// `GET /api/capabilities` and initializes the Supabase client from its
/// `auth` block. Every other HyperVault provider depends on this.
final hyperVaultCapabilitiesProvider = FutureProvider<HvCapabilities>((
  ref,
) async {
  final baseUrl = ref.watch(hyperVaultBaseUrlProvider);
  final service = ref.read(hyperVaultCapabilitiesServiceProvider);
  final authService = ref.read(hyperVaultAuthServiceProvider);
  final capabilities = await service.fetch(baseUrl);
  await authService.initialize(capabilities);
  return capabilities;
});

/// Supabase auth state, live. Emits the restored session (if any) as soon as
/// the client initializes, then follows sign-in/refresh/sign-out events.
final hyperVaultAuthStateProvider = StreamProvider<AuthState?>((ref) async* {
  await ref.watch(hyperVaultCapabilitiesProvider.future);
  final authService = ref.read(hyperVaultAuthServiceProvider);
  final current = authService.currentSession;
  if (current != null) {
    yield AuthState(AuthChangeEvent.initialSession, current);
  } else {
    yield null;
  }
  yield* authService.onAuthStateChange;
});

final hyperVaultSessionProvider = Provider<Session?>((ref) {
  final fromStream = ref.watch(hyperVaultAuthStateProvider).value;
  if (fromStream != null) return fromStream.session;
  final authService = ref.read(hyperVaultAuthServiceProvider);
  return authService.isInitialized ? authService.currentSession : null;
});

final hyperVaultAccessTokenProvider = Provider<String?>((ref) {
  return ref.watch(hyperVaultSessionProvider)?.accessToken;
});

final _hyperVaultDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      // POST /api/chat can run up to 120s server-side (maxDuration 120).
      receiveTimeout: const Duration(seconds: 130),
    ),
  );
});

final hyperVaultConversationLinkServiceProvider =
    Provider<HyperVaultConversationLinkService>((ref) {
      return HyperVaultConversationLinkService(
        ref.read(sharedPreferencesProvider),
      );
    });

final hyperVaultApiClientProvider = Provider<HyperVaultApiClient>((ref) {
  return HyperVaultApiClient(
    ref.read(_hyperVaultDioProvider),
    baseUrlProvider: () => ref.read(hyperVaultBaseUrlProvider),
    accessTokenProvider: () => ref.read(hyperVaultAccessTokenProvider),
  );
});

/// Resolves the invite/waitlist gate by probing a `resolveApiIdentity`
/// route: the server enforces the gate regardless of what the client
/// thinks, so a 403 there is the ground truth for "waitlisted" (mirrors
/// HyperVault docs/mobile/prd/02-auth-onboarding.md T-M2-06 without needing
/// the server's admin-email list on device).
final hyperVaultGateProvider = FutureProvider<HyperVaultGateStatus?>((
  ref,
) async {
  final session = ref.watch(hyperVaultSessionProvider);
  if (session == null) return null;
  final client = ref.read(hyperVaultApiClientProvider);
  try {
    await client.get('/api/artifacts');
    return HyperVaultGateStatus.approved;
  } on HvApiError catch (e) {
    if (e.isWaitlisted) return HyperVaultGateStatus.waitlisted;
    rethrow;
  }
});

/// Keeps a `ServerType.hyperVault` [Server] entry in sync with the current
/// Supabase session so HyperVault shows up in the existing server list /
/// model picker like any other backend, and disappears on sign-out. Reuses
/// [Server.apiKey] to carry the live bearer token (refreshed automatically
/// by Supabase; this listener mirrors it into storage on every change) so
/// the rest of the app's `buildServerAuthHeaders` plumbing needs no special
/// casing for HyperVault.
final hyperVaultServerSyncProvider = Provider<void>((ref) {
  ref.listen<Session?>(hyperVaultSessionProvider, (previous, next) {
    _syncHyperVaultServer(ref, next);
  }, fireImmediately: true);
});

/// Activates the capabilities → auth → server-sync chain only when the user
/// has connected HyperVault before (a `ServerType.hyperVault` [Server] entry
/// already exists locally). Keeps a first-run/local-only user's app from
/// silently phoning home to a HyperVault deployment it never opted into —
/// mirrors LocalMind's "network requests go directly to your servers" claim.
/// Watch this once from the app shell.
final hyperVaultAutoConnectProvider = Provider<void>((ref) {
  final servers = ref.watch(serversProvider).value ?? const <Server>[];
  final hasConnectedBefore = servers.any(
    (s) => s.type == ServerType.hyperVault,
  );
  if (hasConnectedBefore) {
    ref.watch(hyperVaultServerSyncProvider);
  }
});

Future<void> _syncHyperVaultServer(Ref ref, Session? session) async {
  final serversAsync = ref.read(serversProvider);
  final servers = serversAsync.value;
  if (servers == null) return;
  final notifier = ref.read(serversProvider.notifier);
  final existing = servers.where((s) => s.type == ServerType.hyperVault);

  if (session == null) {
    for (final server in existing) {
      await notifier.deleteServer(server.id);
    }
    return;
  }

  final baseUrl = ref.read(hyperVaultBaseUrlProvider);
  final token = session.accessToken;
  final email = session.user.email;
  final name = (email != null && email.isNotEmpty)
      ? 'HyperVault ($email)'
      : 'HyperVault';

  if (existing.isEmpty) {
    await notifier.addServer(
      Server(
        id: 'hypervault-${session.user.id}',
        name: name,
        type: ServerType.hyperVault,
        host: baseUrl,
        port: 0,
        apiKey: token,
        isDefault: servers.isEmpty,
        createdAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
        status: ConnectionStatus.connected,
      ),
    );
    return;
  }

  final current = existing.first;
  if (current.apiKey != token ||
      current.host != baseUrl ||
      current.name != name) {
    await notifier.updateServer(
      current.copyWith(
        apiKey: token,
        host: baseUrl,
        name: name,
        lastConnectedAt: DateTime.now(),
        status: ConnectionStatus.connected,
      ),
    );
  }
}
