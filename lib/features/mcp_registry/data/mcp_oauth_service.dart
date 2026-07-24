import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logger/app_logger.dart';
import '../../deep_links/data/hv_deep_link.dart';

/// Thrown for any failure in the OAuth authorization-code + PKCE flow
/// (discovery, dynamic client registration, user cancellation, or token
/// exchange).
class McpOAuthException implements Exception {
  final String message;
  const McpOAuthException(this.message);

  @override
  String toString() => message;
}

class McpOAuthResult {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const McpOAuthResult({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });
}

class _AuthServerMetadata {
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri? registrationEndpoint;

  const _AuthServerMetadata({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.registrationEndpoint,
  });
}

/// Drives the MCP Authorization spec's OAuth 2.1 + PKCE flow for a remote
/// server that doesn't accept a simple static header — protected-resource
/// metadata discovery (RFC 9728), authorization-server metadata discovery
/// (RFC 8414), optional dynamic client registration (RFC 7591), then a
/// browser-based authorization-code + PKCE exchange.
///
/// The resulting bearer token is handed back to the caller to store —
/// per product decision this app never keeps registry OAuth tokens in
/// on-device storage; they're persisted as an `Authorization` header on the
/// HyperVault-side server record (HyperVault already stores API-key headers
/// securely for the `/api/mcp-servers` and `/api/backends` flows), so this
/// service holds nothing beyond the lifetime of one authorize() call.
class McpOAuthService {
  /// Redirect URI registered as part of the app's existing `hypervault://`
  /// custom scheme (already claimed in Info.plist / AndroidManifest.xml for
  /// the Supabase auth callback) — see `isMcpOAuthCallbackDeepLink`.
  static const String redirectUri = 'hypervault://mcp-oauth-callback';
  static const Duration _callbackTimeout = Duration(minutes: 5);

  final Dio _dio;
  final AppLinks _appLinks;

  McpOAuthService({Dio? dio, AppLinks? appLinks})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {'Content-Type': 'application/json'},
                validateStatus: (_) => true,
              ),
            ),
        _appLinks = appLinks ?? AppLinks();

  /// Probes [remoteUrl] anonymously to check whether it demands
  /// authentication at all. Returns true when the server responds with an
  /// HTTP 401 (the MCP Authorization spec's signal that OAuth discovery
  /// should follow), false when it accepts an unauthenticated request.
  Future<bool> requiresAuth(String remoteUrl) async {
    try {
      final response = await _dio.post<dynamic>(
        remoteUrl,
        data: {
          'jsonrpc': '2.0',
          'id': 0,
          'method': 'initialize',
          'params': {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'localmind-probe', 'version': '1.0.0'},
          },
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.statusCode == 401;
    } catch (_) {
      // Network/transport failure — treat as "unknown", not "needs OAuth".
      return false;
    }
  }

  /// Runs the full authorize flow for [remoteUrl] and returns a bearer
  /// token on success.
  Future<McpOAuthResult> authorize({
    required String remoteUrl,
    required String serverName,
  }) async {
    final metadata = await _discoverMetadata(remoteUrl);
    final clientId = await _registerClient(metadata, serverName);

    final verifier = _randomUrlSafe(64);
    final challengeHash = await Sha256().hash(utf8.encode(verifier));
    // RFC 7636 PKCE code_challenge: base64url without padding.
    final challenge = base64UrlEncode(challengeHash.bytes).replaceAll('=', '');
    final state = _randomUrlSafe(24);

    final authorizationUrl = metadata.authorizationEndpoint.replace(
      queryParameters: {
        ...metadata.authorizationEndpoint.queryParameters,
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'resource': remoteUrl,
      },
    );

    final callback = await _awaitCallback(authorizationUrl);

    if (callback.queryParameters['state'] != state) {
      throw const McpOAuthException(
        'Authorization response did not match the request (state mismatch).',
      );
    }
    final error = callback.queryParameters['error'];
    if (error != null) {
      final description =
          callback.queryParameters['error_description'] ?? error;
      throw McpOAuthException('Authorization failed: $description');
    }
    final code = callback.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const McpOAuthException(
        'Authorization did not return a code.',
      );
    }

    return _exchangeCode(
      metadata: metadata,
      clientId: clientId,
      code: code,
      verifier: verifier,
    );
  }

  /// `Uri.tryParse('')` returns a valid (empty) [Uri] rather than null, so a
  /// plain `Uri.tryParse(json[key]?.toString() ?? '')` can't tell "missing
  /// field" apart from "field present but unparseable" — this treats both
  /// as absent.
  Uri? _parseUri(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }

  Future<_AuthServerMetadata> _discoverMetadata(String remoteUrl) async {
    final resourceOrigin = Uri.parse(remoteUrl).replace(
      path: '',
      query: '',
    );

    Uri? authServerIssuer;
    try {
      final resourceMeta = await _dio.get<dynamic>(
        resourceOrigin.resolve('/.well-known/oauth-protected-resource')
            .toString(),
      );
      if (resourceMeta.statusCode == 200 && resourceMeta.data is Map) {
        final servers =
            (resourceMeta.data as Map)['authorization_servers'];
        if (servers is List && servers.isNotEmpty) {
          authServerIssuer = _parseUri(servers.first.toString());
        }
      }
    } catch (e) {
      Log.debug('[mcp-oauth] protected-resource discovery failed: $e');
    }

    final issuer = authServerIssuer ?? resourceOrigin;
    try {
      final serverMeta = await _dio.get<dynamic>(
        issuer.resolve('/.well-known/oauth-authorization-server').toString(),
      );
      if (serverMeta.statusCode == 200 && serverMeta.data is Map) {
        final data = serverMeta.data as Map;
        final authEndpoint = _parseUri(data['authorization_endpoint']);
        final tokenEndpoint = _parseUri(data['token_endpoint']);
        if (authEndpoint != null && tokenEndpoint != null) {
          return _AuthServerMetadata(
            authorizationEndpoint: authEndpoint,
            tokenEndpoint: tokenEndpoint,
            registrationEndpoint: _parseUri(data['registration_endpoint']),
          );
        }
      }
    } catch (e) {
      Log.debug('[mcp-oauth] authorization-server discovery failed: $e');
    }

    throw McpOAuthException(
      'Could not discover an OAuth authorization server for this MCP server. '
      'It may need a manually-supplied API key instead.',
    );
  }

  Future<String> _registerClient(
    _AuthServerMetadata metadata,
    String serverName,
  ) async {
    final endpoint = metadata.registrationEndpoint;
    if (endpoint == null || endpoint.toString().isEmpty) {
      throw const McpOAuthException(
        'This server does not support dynamic client registration, so it '
        "can't be connected automatically yet.",
      );
    }
    try {
      final response = await _dio.post<dynamic>(
        endpoint.toString(),
        data: {
          'client_name': 'localmind ($serverName)',
          'redirect_uris': [redirectUri],
          'grant_types': ['authorization_code', 'refresh_token'],
          'response_types': ['code'],
          'token_endpoint_auth_method': 'none',
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = response.data;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          data is Map &&
          data['client_id'] != null) {
        return data['client_id'].toString();
      }
    } catch (e) {
      Log.debug('[mcp-oauth] dynamic client registration failed: $e');
    }
    throw const McpOAuthException(
      'Failed to register this app with the server for sign-in.',
    );
  }

  Future<Uri> _awaitCallback(Uri authorizationUrl) async {
    final completer = Completer<Uri>();
    final subscription = _appLinks.uriLinkStream.listen((uri) {
      if (!isMcpOAuthCallbackDeepLink(uri)) return;
      if (!completer.isCompleted) completer.complete(uri);
    }, onError: (Object e) {
      if (!completer.isCompleted) {
        completer.completeError(McpOAuthException('Sign-in failed: $e'));
      }
    });

    try {
      final launched = await launchUrl(
        authorizationUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const McpOAuthException('Could not open the sign-in page.');
      }

      return await completer.future.timeout(
        _callbackTimeout,
        onTimeout: () => throw const McpOAuthException(
          'Sign-in timed out.',
        ),
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<McpOAuthResult> _exchangeCode({
    required _AuthServerMetadata metadata,
    required String clientId,
    required String code,
    required String verifier,
  }) async {
    try {
      final body = Uri(queryParameters: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': verifier,
      }).query;
      final response = await _dio.post<dynamic>(
        metadata.tokenEndpoint.toString(),
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
        ),
      );
      final data = response.data;
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300 && data is Map) {
        final accessToken = data['access_token']?.toString();
        if (accessToken == null || accessToken.isEmpty) {
          throw const McpOAuthException(
            'The server did not return an access token.',
          );
        }
        final expiresIn = data['expires_in'];
        return McpOAuthResult(
          accessToken: accessToken,
          refreshToken: data['refresh_token']?.toString(),
          expiresAt: expiresIn is num
              ? DateTime.now().add(Duration(seconds: expiresIn.toInt()))
              : null,
        );
      }
      throw McpOAuthException(
        'Token exchange failed (${status == 0 ? 'network error' : status}).',
      );
    } on McpOAuthException {
      rethrow;
    } catch (e) {
      throw McpOAuthException('Token exchange failed: $e');
    }
  }

  String _randomUrlSafe(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
