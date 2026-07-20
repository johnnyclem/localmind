/// Mirrors `GET /api/capabilities` — see
/// hypervault-web `docs/mobile/prd/api-contract.md`. This is the single
/// bootstrap call the app uses to configure its base URL, feature flags,
/// limits, provider registry, vanity domain portfolio, and theme catalog.
class HyperVaultCapabilities {
  final String appUrl;
  final String apiVersion;
  final HyperVaultAuthConfig auth;
  final HyperVaultFeatureFlags features;
  final HyperVaultLimits limits;
  final List<HyperVaultProvider> providers;
  final List<HyperVaultDomain> domains;
  final List<HyperVaultTheme> themes;
  final HyperVaultUser? user;

  const HyperVaultCapabilities({
    required this.appUrl,
    required this.apiVersion,
    required this.auth,
    required this.features,
    required this.limits,
    required this.providers,
    required this.domains,
    required this.themes,
    this.user,
  });

  factory HyperVaultCapabilities.fromJson(Map<String, dynamic> json) {
    return HyperVaultCapabilities(
      appUrl: json['app_url'] as String? ?? '',
      apiVersion: json['api_version'] as String? ?? '',
      auth: HyperVaultAuthConfig.fromJson(
        (json['auth'] as Map<String, dynamic>?) ?? const {},
      ),
      features: HyperVaultFeatureFlags.fromJson(
        (json['features'] as Map<String, dynamic>?) ?? const {},
      ),
      limits: HyperVaultLimits.fromJson(
        (json['limits'] as Map<String, dynamic>?) ?? const {},
      ),
      providers: ((json['providers'] as List?) ?? const [])
          .map((e) => HyperVaultProvider.fromJson(e as Map<String, dynamic>))
          .toList(),
      domains: ((json['domains'] as List?) ?? const [])
          .map((e) => HyperVaultDomain.fromJson(e as Map<String, dynamic>))
          .toList(),
      themes: ((json['themes'] as List?) ?? const [])
          .map((e) => HyperVaultTheme.fromJson(e as Map<String, dynamic>))
          .toList(),
      user: json['user'] == null
          ? null
          : HyperVaultUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'app_url': appUrl,
    'api_version': apiVersion,
    'auth': auth.toJson(),
    'features': features.toJson(),
    'limits': limits.toJson(),
    'providers': providers.map((e) => e.toJson()).toList(),
    'domains': domains.map((e) => e.toJson()).toList(),
    'themes': themes.map((e) => e.toJson()).toList(),
    if (user != null) 'user': user!.toJson(),
  };

  HyperVaultCapabilities copyWith({HyperVaultUser? user}) =>
      HyperVaultCapabilities(
        appUrl: appUrl,
        apiVersion: apiVersion,
        auth: auth,
        features: features,
        limits: limits,
        providers: providers,
        domains: domains,
        themes: themes,
        user: user ?? this.user,
      );
}

class HyperVaultAuthConfig {
  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final String bearerHeader;
  final String apiKeyHeader;
  final bool inviteGated;

  const HyperVaultAuthConfig({
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.bearerHeader = 'Authorization',
    this.apiKeyHeader = 'X-HyperVault-Key',
    this.inviteGated = true,
  });

  factory HyperVaultAuthConfig.fromJson(Map<String, dynamic> json) =>
      HyperVaultAuthConfig(
        supabaseUrl: json['supabase_url'] as String?,
        supabaseAnonKey: json['supabase_anon_key'] as String?,
        bearerHeader: json['bearer_header'] as String? ?? 'Authorization',
        apiKeyHeader: json['api_key_header'] as String? ?? 'X-HyperVault-Key',
        inviteGated: json['invite_gated'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'supabase_url': supabaseUrl,
    'supabase_anon_key': supabaseAnonKey,
    'bearer_header': bearerHeader,
    'api_key_header': apiKeyHeader,
    'invite_gated': inviteGated,
  };
}

class HyperVaultFeatureFlags {
  final bool configured;
  final bool deepMemory;
  final bool keyEncryption;
  final bool smartContext;
  final bool onDeviceInference;

  const HyperVaultFeatureFlags({
    this.configured = false,
    this.deepMemory = false,
    this.keyEncryption = true,
    this.smartContext = true,
    this.onDeviceInference = true,
  });

  factory HyperVaultFeatureFlags.fromJson(Map<String, dynamic> json) =>
      HyperVaultFeatureFlags(
        configured: json['configured'] as bool? ?? false,
        deepMemory: json['deep_memory'] as bool? ?? false,
        keyEncryption: json['key_encryption'] as bool? ?? true,
        smartContext: json['smart_context'] as bool? ?? true,
        onDeviceInference: json['on_device_inference'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'configured': configured,
    'deep_memory': deepMemory,
    'key_encryption': keyEncryption,
    'smart_context': smartContext,
    'on_device_inference': onDeviceInference,
  };
}

class HyperVaultLimits {
  final int artifactBytes;
  final int sourcePromptChars;
  final int chatMessageChars;
  final int memoryBytes;
  final int importBytes;
  final int maxBackends;
  final int maxMcpServers;
  final int maxProSubdomains;
  final int rateLimitApiKeyPerMin;
  final int rateLimitUserPerMin;

  const HyperVaultLimits({
    this.artifactBytes = 1000000,
    this.sourcePromptChars = 10000,
    this.chatMessageChars = 100000,
    this.memoryBytes = 500000,
    this.importBytes = 50000000,
    this.maxBackends = 20,
    this.maxMcpServers = 20,
    this.maxProSubdomains = 10,
    this.rateLimitApiKeyPerMin = 60,
    this.rateLimitUserPerMin = 120,
  });

  factory HyperVaultLimits.fromJson(Map<String, dynamic> json) {
    final rate = json['rate_limit_per_min'] as Map<String, dynamic>? ?? const {};
    return HyperVaultLimits(
      artifactBytes: json['artifact_bytes'] as int? ?? 1000000,
      sourcePromptChars: json['source_prompt_chars'] as int? ?? 10000,
      chatMessageChars: json['chat_message_chars'] as int? ?? 100000,
      memoryBytes: json['memory_bytes'] as int? ?? 500000,
      importBytes: json['import_bytes'] as int? ?? 50000000,
      maxBackends: json['max_backends'] as int? ?? 20,
      maxMcpServers: json['max_mcp_servers'] as int? ?? 20,
      maxProSubdomains: json['max_pro_subdomains'] as int? ?? 10,
      rateLimitApiKeyPerMin: rate['api_key'] as int? ?? 60,
      rateLimitUserPerMin: rate['user'] as int? ?? 120,
    );
  }

  Map<String, dynamic> toJson() => {
    'artifact_bytes': artifactBytes,
    'source_prompt_chars': sourcePromptChars,
    'chat_message_chars': chatMessageChars,
    'memory_bytes': memoryBytes,
    'import_bytes': importBytes,
    'max_backends': maxBackends,
    'max_mcp_servers': maxMcpServers,
    'max_pro_subdomains': maxProSubdomains,
    'rate_limit_per_min': {
      'api_key': rateLimitApiKeyPerMin,
      'user': rateLimitUserPerMin,
    },
  };
}

class HyperVaultProvider {
  final String id;
  final Map<String, dynamic> raw;

  const HyperVaultProvider({required this.id, required this.raw});

  factory HyperVaultProvider.fromJson(Map<String, dynamic> json) =>
      HyperVaultProvider(id: json['id'] as String? ?? '', raw: json);

  Map<String, dynamic> toJson() => raw;
}

class HyperVaultDomain {
  final String domain;
  final String tagline;
  final bool featured;
  final bool available;

  const HyperVaultDomain({
    required this.domain,
    required this.tagline,
    required this.featured,
    required this.available,
  });

  factory HyperVaultDomain.fromJson(Map<String, dynamic> json) =>
      HyperVaultDomain(
        domain: json['domain'] as String? ?? '',
        tagline: json['tagline'] as String? ?? '',
        featured: json['featured'] as bool? ?? false,
        available: json['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'domain': domain,
    'tagline': tagline,
    'featured': featured,
    'available': available,
  };
}

class HyperVaultTheme {
  final String id;
  final String name;
  final String mode;

  const HyperVaultTheme({
    required this.id,
    required this.name,
    required this.mode,
  });

  factory HyperVaultTheme.fromJson(Map<String, dynamic> json) =>
      HyperVaultTheme(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        mode: json['mode'] as String? ?? 'dark',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'mode': mode};
}

class HyperVaultUser {
  final String id;
  final String? email;
  final String via;
  final bool isAdmin;

  const HyperVaultUser({
    required this.id,
    this.email,
    required this.via,
    this.isAdmin = false,
  });

  factory HyperVaultUser.fromJson(Map<String, dynamic> json) => HyperVaultUser(
    id: json['id'] as String? ?? '',
    email: json['email'] as String?,
    via: json['via'] as String? ?? 'bearer',
    isAdmin: json['is_admin'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'via': via,
    'is_admin': isAdmin,
  };
}
