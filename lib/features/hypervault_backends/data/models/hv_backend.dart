/// A connected LLM backend from `GET/POST/PATCH/DELETE /api/backends`. The
/// server never returns the raw API key back — [keyHint] is the masked
/// value it hands back instead (e.g. `sk-proj…`).
class HvBackend {
  final String id;
  final String name;
  final String provider;
  final String? baseUrl;
  final String? defaultModel;
  final String? embeddingModel;
  final String? keyHint;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  const HvBackend({
    required this.id,
    required this.name,
    required this.provider,
    this.baseUrl,
    this.defaultModel,
    this.embeddingModel,
    this.keyHint,
    this.createdAt,
    this.lastUsedAt,
  });

  factory HvBackend.fromJson(Map<String, dynamic> json) {
    return HvBackend(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      baseUrl: json['base_url'] as String?,
      defaultModel: json['default_model'] as String?,
      embeddingModel: json['embedding_model'] as String?,
      keyHint: json['key_hint'] as String?,
      createdAt: _parseDate(json['created_at']),
      lastUsedAt: _parseDate(json['last_used_at']),
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

/// Generic view of a provider registry entry (`GET /api/backends.providers`,
/// same shape as `GET /api/capabilities.providers`). Read defensively via raw
/// map access rather than a strict schema, so an unrecognized/extended
/// provider still renders instead of the app crashing.
class HvProviderSpec {
  final Map<String, dynamic> raw;

  const HvProviderSpec(this.raw);

  factory HvProviderSpec.fromJson(Map<String, dynamic> json) =>
      HvProviderSpec(json);

  String get id => raw['id']?.toString() ?? '';
  String get label => raw['label']?.toString() ?? id;
  String get protocol => raw['protocol']?.toString() ?? '';
  String get defaultBaseUrl => raw['defaultBaseUrl']?.toString() ?? '';
  String get defaultModel => raw['defaultModel']?.toString() ?? '';
  bool get requiresKey => raw['requiresKey'] == true;
  bool get optionalKey => raw['optionalKey'] == true;
  String? get defaultEmbeddingModel => raw['defaultEmbeddingModel']?.toString();

  bool get isCustom => id == 'custom' || id == 'custom-anthropic';
  bool get isLocalRuntime => id == 'ollama' || id == 'lmstudio';

  /// Only OpenAI-protocol backends expose `/embeddings` (spec T-M10-05).
  bool get supportsEmbeddings => protocol == 'openai';
}

/// Result of `POST`/`PATCH /api/backends` — the saved row plus the server's
/// human-readable outcome message (e.g. "Connected — test reply received
/// from gpt-4o.").
class HvBackendMutationResult {
  final HvBackend backend;
  final String message;

  const HvBackendMutationResult({required this.backend, required this.message});
}

/// `GET /api/backends` response: the caller's connected backends plus the
/// provider registry used to render the connect/edit form.
class HvBackendsSnapshot {
  final List<HvBackend> backends;
  final List<HvProviderSpec> providers;

  const HvBackendsSnapshot({
    this.backends = const [],
    this.providers = const [],
  });

  HvProviderSpec? specFor(String providerId) {
    for (final spec in providers) {
      if (spec.id == providerId) return spec;
    }
    return null;
  }
}
