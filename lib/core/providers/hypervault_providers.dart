import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../logger/app_logger.dart';
import '../models/hypervault_capabilities.dart';
import '../network/auth_token_holder.dart';
import '../network/base_url_holder.dart';
import '../network/hypervault_api_exception.dart';
import '../network/hypervault_client.dart';
import '../storage/hypervault_cache.dart';
import 'storage_providers.dart';

/// App-supported api_version window (spec §11). Bump the min when a breaking
/// mobile-facing change lands upstream; capabilities older/newer than this
/// window trigger the soft "update available" prompt (M16).
const _supportedApiVersion = '2026-07-15';

const _customBaseUrlPrefsKey = 'hypervaultCustomBaseUrl';

final authTokenHolderProvider = Provider<AuthTokenHolder>((ref) {
  return AuthTokenHolder();
});

/// User-supplied override for the HyperVault deployment origin, for people
/// running a self-hosted instance instead of the hosted
/// [AppConstants.hypervaultDefaultBaseUrl]. `null` (the default) means "use
/// the hosted deployment". Persisted so the choice survives restarts; set
/// from the "Self-hosted deployment?" field on the sign-in screen.
final customBaseUrlProvider = NotifierProvider<CustomBaseUrlNotifier, String?>(
  CustomBaseUrlNotifier.new,
);

class CustomBaseUrlNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_customBaseUrlPrefsKey);
  }

  /// Sets (or, given `null`/empty, clears) the self-hosted base URL.
  void setCustomBaseUrl(String? url) {
    final prefs = ref.read(sharedPreferencesProvider);
    if (url == null || url.trim().isEmpty) {
      prefs.remove(_customBaseUrlPrefsKey);
      state = null;
      return;
    }
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    prefs.setString(_customBaseUrlPrefsKey, normalized);
    state = normalized;
  }
}

final baseUrlHolderProvider = Provider<BaseUrlHolder>((ref) {
  final holder = BaseUrlHolder();
  holder.setOverride(ref.watch(customBaseUrlProvider));
  return holder;
});

/// The base URL [CapabilitiesNotifier] targets right now: the user's
/// self-hosted override if one is set, else the hosted default. Handy for UI
/// that wants to show which deployment it's talking to without reaching into
/// [BaseUrlHolder] directly.
final effectiveBaseUrlProvider = Provider<String>((ref) {
  final custom = ref.watch(customBaseUrlProvider);
  return (custom != null && custom.isNotEmpty)
      ? custom
      : AppConstants.hypervaultDefaultBaseUrl;
});

final hyperVaultCacheProvider = Provider<HyperVaultCache>((ref) {
  return HyperVaultCache(ref.watch(sharedPreferencesProvider));
});

final hypervaultClientProvider = Provider<HyperVaultClient>((ref) {
  final tokenHolder = ref.watch(authTokenHolderProvider);
  final baseUrlHolder = ref.watch(baseUrlHolderProvider);
  final dio = HyperVaultClient.buildDio(
    baseUrlProvider: () => baseUrlHolder.baseUrl,
    tokenHolder: tokenHolder,
    onRequestComplete: (method, path, status, elapsed) {
      Log.debug('[hypervault] $method $path -> $status (${elapsed.inMilliseconds}ms)');
    },
  );
  return HyperVaultClient(dio);
});

/// `GET /api/capabilities` — public, enriched with a `user` block when a
/// credential is present (M2 supplies it via [refreshWithAuth]). Cached for
/// stale-while-revalidate cold starts (T-M1-04).
class CapabilitiesNotifier extends AsyncNotifier<HyperVaultCapabilities> {
  static const _cacheKey = 'capabilities';

  @override
  Future<HyperVaultCapabilities> build() async {
    final cache = ref.watch(hyperVaultCacheProvider);
    final cached = cache.read(_cacheKey);
    if (cached is Map<String, dynamic>) {
      // Serve cached value instantly, then revalidate in the background.
      unawaited(_refresh());
      final capabilities = HyperVaultCapabilities.fromJson(cached);
      ref.watch(baseUrlHolderProvider).set(capabilities.appUrl);
      return capabilities;
    }
    return _fetch();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> _refresh() async {
    try {
      final fresh = await _fetch();
      state = AsyncData(fresh);
    } catch (e) {
      // Keep serving the cached value; this was a background revalidation.
      Log.warning('[hypervault] capabilities revalidate failed: $e');
    }
  }

  Future<HyperVaultCapabilities> _fetch() async {
    final client = ref.read(hypervaultClientProvider);
    try {
      final json = await client.get<Map<String, dynamic>>('/api/capabilities');
      final capabilities = HyperVaultCapabilities.fromJson(json);
      ref.read(baseUrlHolderProvider).set(capabilities.appUrl);
      await ref.read(hyperVaultCacheProvider).put(_cacheKey, json);
      return capabilities;
    } on HyperVaultApiException {
      rethrow;
    }
  }

  /// True when the running app is older/newer than the server's supported
  /// window — drives the non-blocking "update available" prompt (M16).
  bool get isVersionSkewed {
    final value = state.value;
    if (value == null || value.apiVersion.isEmpty) return false;
    return value.apiVersion != _supportedApiVersion;
  }
}

final capabilitiesProvider =
    AsyncNotifierProvider<CapabilitiesNotifier, HyperVaultCapabilities>(
      CapabilitiesNotifier.new,
    );

void unawaited(Future<void> future) {
  // Intentionally fire-and-forget background revalidation.
}
