import '../../../../core/models/hypervault_capabilities.dart';

/// A HyperVault server-side "backend" — a connected LLM provider (OpenAI,
/// Anthropic, Ollama, LM Studio, or a custom OpenAI-/Anthropic-compatible
/// endpoint) available to drive chat. Mirrors `GET/POST/PATCH /api/backends`
/// — see hypervault-web `docs/mobile/prd/10-byo-llm-backends.md`.
class Backend {
  final String id;
  final String name;
  final String provider;
  final String? baseUrl;
  final String? defaultModel;
  final String? embeddingModel;
  final String? keyHint;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const Backend({
    required this.id,
    required this.name,
    required this.provider,
    this.baseUrl,
    this.defaultModel,
    this.embeddingModel,
    this.keyHint,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory Backend.fromJson(Map<String, dynamic> json) {
    return Backend(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      baseUrl: json['base_url'] as String?,
      defaultModel: json['default_model'] as String?,
      embeddingModel: json['embedding_model'] as String?,
      keyHint: json['key_hint'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.tryParse(json['last_used_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'provider': provider,
    'base_url': baseUrl,
    'default_model': defaultModel,
    'embedding_model': embeddingModel,
    'key_hint': keyHint,
    'created_at': createdAt.toIso8601String(),
    'last_used_at': lastUsedAt?.toIso8601String(),
  };
}

/// Response shape of `GET /api/backends`: the user's connected backends plus
/// the provider registry (same shape as `capabilities.providers`).
class BackendsListResult {
  final List<Backend> backends;
  final List<HyperVaultProvider> providers;

  const BackendsListResult({required this.backends, required this.providers});

  factory BackendsListResult.fromJson(Map<String, dynamic> json) {
    return BackendsListResult(
      backends: ((json['backends'] as List?) ?? const [])
          .map((e) => Backend.fromJson(e as Map<String, dynamic>))
          .toList(),
      providers: ((json['providers'] as List?) ?? const [])
          .map((e) => HyperVaultProvider.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'backends': backends.map((e) => e.toJson()).toList(),
    'providers': providers.map((e) => e.toJson()).toList(),
  };

  BackendsListResult copyWith({
    List<Backend>? backends,
    List<HyperVaultProvider>? providers,
  }) => BackendsListResult(
    backends: backends ?? this.backends,
    providers: providers ?? this.providers,
  );
}
