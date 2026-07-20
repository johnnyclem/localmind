import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'l10n/app_localizations.dart';

import 'core/models/enums.dart';
import 'core/providers/app_providers.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/locale_utils.dart';
import 'core/widgets/placeholder_screen.dart';
import 'features/auth/data/models/auth_gate_status.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/views/sign_in_screen.dart';
import 'features/auth/views/waitlist_screen.dart';
import 'features/chat/providers/chat_providers.dart';
import 'features/deep_links/data/hv_deep_link.dart';
import 'features/deep_links/providers/deep_link_providers.dart';
import 'features/vault/views/vault_list_screen.dart';
import 'features/vault/views/save_artifact_screen.dart';
import 'features/vault/views/artifact_detail_screen.dart';
import 'features/backends/views/backends_list_screen.dart';
import 'features/backends/views/add_backend_screen.dart';
import 'features/backends/data/models/backend.dart' as hv_backend;
import 'features/hv_tools/views/hv_tools_console_screen.dart';
import 'features/import_history/views/import_history_screen.dart';
import 'features/domains/views/domains_screen.dart';
import 'features/memory/views/memory_screen.dart';
import 'features/memory/views/memory_detail_screen.dart';
import 'features/vault_graph/views/vault_graph_screen.dart';
import 'features/connections/views/shared_with_me_screen.dart';
import 'features/admin/views/admin_screen.dart';
import 'features/hv_chat/views/hv_chat_list_screen.dart';
import 'features/hv_chat/views/hv_chat_thread_screen.dart';
import 'features/git_mind/views/git_mind_screen.dart';
import 'features/conversations/providers/conversation_providers.dart' as conv;
import 'features/chat/views/chat_screen.dart';
import 'features/conversations/views/chat_history_screen.dart';
import 'features/mcp/views/mcp_tools_screen.dart';
import 'features/on_device/views/model_manager_screen.dart';
import 'features/onboarding/screens/onboarding_language_screen.dart';
import 'features/onboarding/screens/onboarding_model_download_screen.dart';
import 'features/onboarding/screens/onboarding_notification_permission_screen.dart';
import 'features/onboarding/screens/onboarding_server_setup_screen.dart';
import 'features/onboarding/screens/onboarding_server_type_screen.dart';
import 'features/onboarding/screens/onboarding_theme_screen.dart';
import 'features/personas/views/create_persona_screen.dart';
import 'features/personas/views/persona_list_screen.dart';
import 'features/servers/data/models/server.dart';
import 'features/servers/views/add_server_screen.dart';
import 'features/servers/views/server_list_screen.dart';
import 'features/tts/views/tts_model_manager_screen.dart';
import 'features/saved_messages/views/saved_messages_screen.dart';
import 'features/settings/views/settings_screen.dart';
import 'features/cloud_sync/views/cloud_sync_screen.dart';
import 'features/lm_studio_catalog/views/lm_studio_model_browser_screen.dart';
import 'features/sidebar/sidebar_drawer.dart';
import 'features/sidebar/sidebar_widget.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod state changes into go_router's `refreshListenable` so
/// the redirect below re-evaluates reactively (e.g. a background token
/// refresh failure signs the user out mid-session, not just on the next
/// explicit navigation).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider.select((s) => s.status), (_, _) => notifyListeners());
    ref.listen(
      settingsProvider.select((s) => s.hasCompletedOnboarding),
      (_, _) => notifyListeners(),
    );
    // A newly-resolved deep link (cold or warm start) should re-run the
    // redirect below even if auth/onboarding state hasn't changed.
    ref.listen(deepLinkProvider, (_, _) => notifyListeners());
  }
}

/// `?next=` is only ever honored as a redirect target when it's a safe,
/// same-origin relative path — never an absolute URL or a scheme-relative
/// `//host/...` one, which could otherwise be used to bounce the app to an
/// attacker-controlled destination via a crafted deep link.
bool _isSafeDeepLinkRedirectPath(String path) =>
    path.startsWith('/') && !path.startsWith('//');

/// Turns an already-resolved [HvDeepLink] into a router location, or `null`
/// if this link kind isn't wired to a route yet (parsed, but not routed —
/// see the callers of [deepLinkProvider] for what's actually navigated).
///
/// Invite links are deliberately not handled here — they need to redirect
/// even while the user is only `waitlisted` (not yet `approved`), which is
/// handled directly in the `redirect:` switch below instead.
String? _deepLinkRedirectTarget(HvDeepLink link) {
  switch (link) {
    case HvOpenArtifactDeepLink(:final slug):
      return '${AppRoutes.artifactDetail}?slug=${Uri.encodeQueryComponent(slug)}';
    case HvOpenConversationDeepLink(:final slug):
      return '${AppRoutes.hvChatThread}?conversationId=${Uri.encodeQueryComponent(slug)}';
    case HvOpenItemDeepLink(:final id, :final path):
      // Best-effort: the id alone is ambiguous (vault item vs. memory item),
      // so only route it when the path it rode in on hints at "memory".
      // Anything else is parsed but left unrouted rather than guessed at.
      if (path.contains('memory')) {
        return '${AppRoutes.memoryDetail}?memoryId=${Uri.encodeQueryComponent(id)}';
      }
      return null;
    case HvUnknownDeepLink(:final uri):
      final next = hvDeepLinkNextParam(uri);
      if (next != null && _isSafeDeepLinkRedirectPath(next)) return next;
      return null;
    case HvInviteDeepLink():
    case HvNewFromChatDeepLink():
    case HvBranchDeepLink():
      // Parsed, not yet routed — see the class docs on
      // lib/features/deep_links/data/hv_deep_link.dart for what these mean.
      return null;
  }
}

final _routerRefreshNotifierProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: ref.watch(_routerRefreshNotifierProvider),
    redirect: (context, state) {
      final hasCompletedOnboarding = ref
          .read(settingsProvider)
          .hasCompletedOnboarding;
      final location = state.uri.toString();
      final isGoingToOnboarding = location.startsWith('/onboarding');
      final isGoingToAuth = location.startsWith('/auth');

      if (!hasCompletedOnboarding && !isGoingToOnboarding) {
        return AppRoutes.onboarding;
      }

      if (hasCompletedOnboarding && isGoingToOnboarding) {
        return AppRoutes.home;
      }

      // HyperVault auth gate only applies once local onboarding is done —
      // onboarding covers device/model setup unrelated to the account.
      if (hasCompletedOnboarding && !isGoingToOnboarding) {
        final authStatus = ref.read(authProvider).status;
        switch (authStatus) {
          case AuthGateStatus.loading:
            return null;
          case AuthGateStatus.unauthenticated:
            return isGoingToAuth ? null : AppRoutes.authSignIn;
          case AuthGateStatus.waitlisted:
            // An invite deep link (`?invite=<code>`) should prefill the
            // redeem field even if the user landed here from onboarding
            // rather than from the link directly — honor it once, then
            // fall back to the plain waitlist redirect.
            final pendingInvite = ref.read(deepLinkProvider);
            if (pendingInvite is HvInviteDeepLink && pendingInvite.code != null) {
              final target =
                  '${AppRoutes.authWaitlist}?code=${Uri.encodeQueryComponent(pendingInvite.code!)}';
              if (location != target) {
                ref.read(deepLinkProvider.notifier).consume();
                return target;
              }
            }
            return location == AppRoutes.authWaitlist
                ? null
                : AppRoutes.authWaitlist;
          case AuthGateStatus.approved:
            if (isGoingToAuth) return AppRoutes.home;
            final pending = ref.read(deepLinkProvider);
            if (pending != null) {
              final target = _deepLinkRedirectTarget(pending);
              ref.read(deepLinkProvider.notifier).consume();
              if (target != null) return target;
            }
            return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.authSignIn,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SignInScreen()),
      ),
      GoRoute(
        path: AppRoutes.authWaitlist,
        pageBuilder: (context, state) => MaterialPage(
          child: WaitlistScreen(initialCode: state.uri.queryParameters['code']),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            const MaterialPage(child: OnboardingLanguageScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingServerType,
        pageBuilder: (context, state) =>
            const MaterialPage(child: OnboardingServerTypeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingSetup,
        pageBuilder: (context, state) {
          final serverType = state.extra as ServerType?;
          return MaterialPage(
            child: OnboardingServerSetupScreen(
              selectedType: serverType ?? ServerType.lmStudio,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboardingModelDownload,
        pageBuilder: (context, state) =>
            const MaterialPage(child: OnboardingModelDownloadScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingTheme,
        pageBuilder: (context, state) =>
            const MaterialPage(child: OnboardingThemeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingNotifications,
        pageBuilder: (context, state) =>
            const MaterialPage(child: OnboardingNotificationPermissionScreen()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ChatScreen()),
          ),
          GoRoute(
            path: AppRoutes.servers,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ServerListScreen()),
          ),
          GoRoute(
            path: AppRoutes.addServer,
            pageBuilder: (context, state) {
              final server = state.extra as Server?;
              return MaterialPage(child: AddServerScreen(editServer: server));
            },
          ),
          GoRoute(
            path: AppRoutes.personas,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PersonaListScreen()),
          ),
          GoRoute(
            path: AppRoutes.createPersona,
            pageBuilder: (context, state) {
              final persona = state.extra as dynamic;
              return MaterialPage(
                child: CreatePersonaScreen(editPersona: persona),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsViews()),
          ),
          GoRoute(
            path: AppRoutes.cloudSync,
            pageBuilder: (context, state) =>
                const MaterialPage(child: CloudSyncScreen()),
          ),
          GoRoute(
            path: AppRoutes.chatHistory,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ChatHistoryScreen()),
          ),
          GoRoute(
            path: AppRoutes.mcpTools,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: McpToolsScreen()),
          ),
          GoRoute(
            path: AppRoutes.onDeviceModels,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OnDeviceModelManagerScreen()),
          ),
          GoRoute(
            path: AppRoutes.ttsModels,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TtsModelManagerScreen()),
          ),
          GoRoute(
            path: AppRoutes.savedMessages,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SavedMessagesScreen()),
          ),
          GoRoute(
            path: AppRoutes.lmStudioModelBrowser,
            pageBuilder: (context, state) {
              final server = state.extra as Server?;
              if (server == null) {
                return const MaterialPage(child: SizedBox.shrink());
              }
              return MaterialPage(
                child: LmStudioModelBrowserScreen(server: server),
              );
            },
          ),
          // HyperVault — placeholder screens until each epic lands.
          GoRoute(
            path: AppRoutes.vault,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VaultListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.vaultGraph,
            pageBuilder: (context, state) => const MaterialPage(
              child: VaultGraphScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.artifactDetail,
            pageBuilder: (context, state) {
              // `state.extra` for normal in-app navigation (see
              // vault_list_screen.dart); `?slug=` for the deep-link redirect
              // in lib/app.dart's `redirect:`, which can't carry `extra`.
              final slug =
                  (state.extra as String?) ?? state.uri.queryParameters['slug'];
              if (slug == null) {
                return const MaterialPage(child: SizedBox.shrink());
              }
              return MaterialPage(child: ArtifactDetailScreen(slug: slug));
            },
          ),
          GoRoute(
            path: AppRoutes.saveArtifact,
            pageBuilder: (context, state) =>
                const MaterialPage(child: SaveArtifactScreen()),
          ),
          GoRoute(
            path: AppRoutes.sharedWithMe,
            pageBuilder: (context, state) => const MaterialPage(
              child: SharedWithMeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.memory,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MemoryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.memoryDetail,
            pageBuilder: (context, state) {
              // `state.extra` for normal in-app navigation; `?memoryId=` for
              // the deep-link redirect in lib/app.dart's `redirect:`.
              final memoryId = (state.extra as String?) ??
                  state.uri.queryParameters['memoryId'];
              if (memoryId == null) {
                return const MaterialPage(child: SizedBox.shrink());
              }
              return MaterialPage(
                child: MemoryDetailScreen(memoryId: memoryId),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.memoryGraph,
            pageBuilder: (context, state) => const MaterialPage(
              child: PlaceholderScreen(title: 'Memory Graph'),
            ),
          ),
          GoRoute(
            path: AppRoutes.gitMind,
            pageBuilder: (context, state) => const MaterialPage(
              child: GitMindScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.hvChat,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HvChatListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.hvChatThread,
            pageBuilder: (context, state) => MaterialPage(
              child: HvChatThreadScreen(
                conversationId: state.extra as String?,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.backends,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BackendsListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.addBackend,
            pageBuilder: (context, state) => MaterialPage(
              child: AddBackendScreen(
                editBackend: state.extra as hv_backend.Backend?,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.mcpToolsConsole,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: McpToolsConsoleScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.importHistory,
            pageBuilder: (context, state) => const MaterialPage(
              child: ImportHistoryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.domains,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DomainsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.admin,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appThemeType = ref.watch(themeModeProvider);
    final localeCode = ref.watch(settingsProvider.select((s) => s.localeCode));
    final selectedLocale = findSupportedLocale(
      localeCode,
      AppLocalizations.supportedLocales,
    );

    ThemeData theme = AppTheme.lightTheme;
    ThemeData darkTheme = AppTheme.darkTheme;
    ThemeMode themeMode = ThemeMode.system;

    var shadTheme = AppTheme.lightShadTheme;
    var shadDarkTheme = AppTheme.darkShadTheme;

    switch (appThemeType) {
      case AppThemeType.light:
        themeMode = ThemeMode.light;
        shadTheme = AppTheme.lightShadTheme;
        break;
      case AppThemeType.dark:
        themeMode = ThemeMode.dark;
        shadTheme = AppTheme.darkShadTheme;
        // Also ensure shadDarkTheme matches so there's no mismatch
        shadDarkTheme = AppTheme.darkShadTheme;
        break;
      case AppThemeType.claude:
        themeMode = ThemeMode.light; // Force light mode for claude basically
        theme = AppTheme.claudeTheme;
        shadTheme = AppTheme.claudeShadTheme;
        break;
      case AppThemeType.system:
        themeMode = ThemeMode.system;
        shadTheme = AppTheme.lightShadTheme;
        shadDarkTheme = AppTheme.darkShadTheme;
        break;
    }

    return ShadApp.custom(
      themeMode: themeMode,
      theme: shadTheme,
      darkTheme: shadDarkTheme,
      appBuilder: (context) {
        return MaterialApp.router(
          title: 'LocalMind',
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: selectedLocale,
          localeResolutionCallback: (locale, supportedLocales) {
            if (selectedLocale != null) {
              return selectedLocale;
            }
            for (final l in supportedLocales) {
              if (l.languageCode == locale?.languageCode) return l;
            }
            return const Locale('en');
          },
          builder: (context, child) {
            return ShadAppBuilder(child: child!);
          },
        );
      },
    );
  }
}

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static void openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;
    final isHome = location == AppRoutes.home;
    final hasActiveChat = ref.watch(conv.activeConversationProvider) != null;

    return PopScope(
      canPop: isHome && !hasActiveChat,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isHome && hasActiveChat) {
          final origin = ref.read(chatOriginProvider);
          ref.read(chatOriginProvider.notifier).clear();
          switch (origin) {
            case ChatOrigin.history:
              context.go(AppRoutes.chatHistory);
            case ChatOrigin.savedMessages:
              context.go(AppRoutes.savedMessages);
            case ChatOrigin.none:
              ref.read(chatProvider.notifier).startNewConversation();
          }
          return;
        }
        if (!isHome) {
          context.go(AppRoutes.home);
        }
      },
      child: ShadResponsiveBuilder(
        builder: (context, breakpoint) {
          final isDesktop = breakpoint >= ShadTheme.of(context).breakpoints.md;

          if (isDesktop) {
            return Scaffold(
              body: Row(
                children: [
                  const SidebarWidget(),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFE5E5E5),
                  ),
                  Expanded(child: child),
                ],
              ),
            );
          }

          return Scaffold(body: child, drawer: const ConversationDrawer());
        },
      ),
    );
  }
}
