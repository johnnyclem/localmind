/// Typed view of `GET /api/capabilities` — the bootstrap descriptor a
/// HyperVault client uses to configure itself: base URL, auth config,
/// feature flags, limits, provider registry, vanity domain portfolio, and
/// theme catalog. See docs/mobile/prd/api-contract.md in the hypervault repo.
class HvCapabilities {
  final String appUrl;
  final String apiVersion;
  final HvAuthConfig auth;
  final HvFeatureFlags features;
  final HvLimits limits;
  final List<Map<String, dynamic>> providers;
  final List<HvDomain> domains;
  final List<HvTheme> themes;
  final HvCapabilitiesUser? user;

  const HvCapabilities({
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

  factory HvCapabilities.fromJson(Map<String, dynamic> json) {
    return HvCapabilities(
      appUrl: json['app_url'] as String? ?? '',
      apiVersion: json['api_version'] as String? ?? '',
      auth: HvAuthConfig.fromJson(
        (json['auth'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      features: HvFeatureFlags.fromJson(
        (json['features'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      limits: HvLimits.fromJson(
        (json['limits'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      providers: ((json['providers'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
      domains: ((json['domains'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvDomain.fromJson(e.cast<String, dynamic>()))
          .toList(),
      themes: ((json['themes'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvTheme.fromJson(e.cast<String, dynamic>()))
          .toList(),
      user: json['user'] is Map
          ? HvCapabilitiesUser.fromJson(
              (json['user'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'app_url': appUrl,
    'api_version': apiVersion,
    'auth': auth.toJson(),
    'features': features.toJson(),
    'limits': limits.toJson(),
    'providers': providers,
    'domains': domains.map((d) => d.toJson()).toList(),
    'themes': themes.map((t) => t.toJson()).toList(),
    if (user != null) 'user': user!.toJson(),
  };
}

class HvAuthConfig {
  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final String bearerHeader;
  final String apiKeyHeader;
  final bool inviteGated;

  const HvAuthConfig({
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.bearerHeader = 'Authorization',
    this.apiKeyHeader = 'X-HyperVault-Key',
    this.inviteGated = true,
  });

  factory HvAuthConfig.fromJson(Map<String, dynamic> json) {
    return HvAuthConfig(
      supabaseUrl: json['supabase_url'] as String?,
      supabaseAnonKey: json['supabase_anon_key'] as String?,
      bearerHeader: json['bearer_header'] as String? ?? 'Authorization',
      apiKeyHeader: json['api_key_header'] as String? ?? 'X-HyperVault-Key',
      inviteGated: json['invite_gated'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'supabase_url': supabaseUrl,
    'supabase_anon_key': supabaseAnonKey,
    'bearer_header': bearerHeader,
    'api_key_header': apiKeyHeader,
    'invite_gated': inviteGated,
  };
}

class HvFeatureFlags {
  final bool configured;
  final bool deepMemory;
  final bool keyEncryption;
  final bool smartContext;
  final bool onDeviceInference;

  const HvFeatureFlags({
    this.configured = false,
    this.deepMemory = false,
    this.keyEncryption = false,
    this.smartContext = false,
    this.onDeviceInference = false,
  });

  factory HvFeatureFlags.fromJson(Map<String, dynamic> json) {
    return HvFeatureFlags(
      configured: json['configured'] as bool? ?? false,
      deepMemory: json['deep_memory'] as bool? ?? false,
      keyEncryption: json['key_encryption'] as bool? ?? false,
      smartContext: json['smart_context'] as bool? ?? false,
      onDeviceInference: json['on_device_inference'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'configured': configured,
    'deep_memory': deepMemory,
    'key_encryption': keyEncryption,
    'smart_context': smartContext,
    'on_device_inference': onDeviceInference,
  };
}

class HvLimits {
  final int artifactBytes;
  final int sourcePromptChars;
  final int chatMessageChars;
  final int memoryBytes;
  final int importBytes;
  final int maxBackends;
  final int maxMcpServers;
  final int maxProSubdomains;
  final Map<String, int> rateLimitPerMin;

  const HvLimits({
    this.artifactBytes = 1000000,
    this.sourcePromptChars = 10000,
    this.chatMessageChars = 100000,
    this.memoryBytes = 500000,
    this.importBytes = 50000000,
    this.maxBackends = 20,
    this.maxMcpServers = 20,
    this.maxProSubdomains = 10,
    this.rateLimitPerMin = const {},
  });

  factory HvLimits.fromJson(Map<String, dynamic> json) {
    final rateLimitRaw = (json['rate_limit_per_min'] as Map?)
        ?.cast<String, dynamic>();
    return HvLimits(
      artifactBytes: json['artifact_bytes'] as int? ?? 1000000,
      sourcePromptChars: json['source_prompt_chars'] as int? ?? 10000,
      chatMessageChars: json['chat_message_chars'] as int? ?? 100000,
      memoryBytes: json['memory_bytes'] as int? ?? 500000,
      importBytes: json['import_bytes'] as int? ?? 50000000,
      maxBackends: json['max_backends'] as int? ?? 20,
      maxMcpServers: json['max_mcp_servers'] as int? ?? 20,
      maxProSubdomains: json['max_pro_subdomains'] as int? ?? 10,
      rateLimitPerMin:
          rateLimitRaw?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          const {},
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
    'rate_limit_per_min': rateLimitPerMin,
  };
}

class HvDomain {
  final String domain;
  final String? tagline;
  final bool featured;
  final bool available;

  const HvDomain({
    required this.domain,
    this.tagline,
    this.featured = false,
    this.available = true,
  });

  factory HvDomain.fromJson(Map<String, dynamic> json) {
    return HvDomain(
      domain: json['domain'] as String? ?? '',
      tagline: json['tagline'] as String?,
      featured: json['featured'] as bool? ?? false,
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'domain': domain,
    'tagline': tagline,
    'featured': featured,
    'available': available,
  };
}

class HvTheme {
  final String id;
  final String name;
  final String mode;

  const HvTheme({required this.id, required this.name, required this.mode});

  factory HvTheme.fromJson(Map<String, dynamic> json) {
    return HvTheme(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mode: json['mode'] as String? ?? 'dark',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'mode': mode};
}

class HvCapabilitiesUser {
  final String id;
  final String? email;
  final String via;

  const HvCapabilitiesUser({
    required this.id,
    this.email,
    required this.via,
  });

  factory HvCapabilitiesUser.fromJson(Map<String, dynamic> json) {
    return HvCapabilitiesUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      via: json['via'] as String? ?? 'bearer',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'via': via};
}
