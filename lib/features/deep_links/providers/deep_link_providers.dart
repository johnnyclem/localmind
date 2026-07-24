import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger/app_logger.dart';
import '../data/hv_deep_link.dart';

/// Owns the `app_links` subscription and exposes the most recently resolved
/// HyperVault deep link as Riverpod state, so `lib/app.dart`'s router
/// `redirect:` can react to it. Listens to [AppLinks.uriLinkStream] for
/// warm-start links (app already running) and [AppLinks.getInitialLink] for
/// cold-start (app launched by tapping the link).
///
/// Riverpod 3.x dropped `StateProvider` — this is a plain
/// `Notifier<HvDeepLink?>`, mirroring the convention documented on
/// `SelectedGitMindBranchNotifier` in
/// `lib/features/git_mind/providers/git_mind_providers.dart`.
///
/// Auth-callback URLs (`hypervault://auth/*`, `/auth/*`) are deliberately
/// never surfaced here — those are Supabase's own `app_links` listener's job
/// (wired inside `supabase_flutter`/[HyperVaultAuthState]'s OAuth redirect),
/// and double-handling them here would race that listener.
class DeepLinkNotifier extends Notifier<HvDeepLink?> {
  StreamSubscription<Uri>? _subscription;
  AppLinks? _appLinks;

  @override
  HvDeepLink? build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    Future.microtask(_bootstrap);
    return null;
  }

  Future<void> _bootstrap() async {
    final appLinks = _appLinks ??= AppLinks();

    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (e) {
      Log.warning('[deep_links] getInitialLink failed: $e');
    }

    _subscription = appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) =>
          Log.warning('[deep_links] uriLinkStream error: $e'),
    );
  }

  void _handleUri(Uri uri) {
    // Not ours to handle — Supabase's own listener resolves the session
    // from this URL.
    if (isHvAuthCallbackDeepLink(uri)) return;
    // Not ours either — McpOAuthService has its own subscription and
    // resolves this one directly.
    if (isMcpOAuthCallbackDeepLink(uri)) return;

    final parsed = parseHyperVaultDeepLink(uri);
    if (parsed == null) return;
    state = parsed;
  }

  /// Called once the router redirect has acted on [state] so the same link
  /// doesn't re-trigger navigation on the next unrelated route change.
  void consume() {
    state = null;
  }
}

final deepLinkProvider = NotifierProvider<DeepLinkNotifier, HvDeepLink?>(
  DeepLinkNotifier.new,
);
