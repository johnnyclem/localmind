import '../../../core/models/hypervault_capabilities.dart';

/// Small hardcoded fallback registry used only when `capabilities.providers`
/// hasn't loaded yet (cold start / offline). The server registry
/// (`capabilities.providers`) is always preferred when available — never
/// hard-code provider fields for the "real" flow, only for this bootstrap
/// fallback (per PRD M10 notes).
final List<HyperVaultProvider> fallbackProviders = [
  const HyperVaultProvider(
    id: 'openai',
    raw: {
      'id': 'openai',
      'name': 'OpenAI',
      'protocol': 'openai',
      'requiresKey': true,
      'defaultModel': 'gpt-4o-mini',
      'defaultEmbeddingModel': 'text-embedding-3-small',
    },
  ),
  const HyperVaultProvider(
    id: 'anthropic',
    raw: {
      'id': 'anthropic',
      'name': 'Anthropic',
      'protocol': 'anthropic',
      'requiresKey': true,
      'defaultModel': 'claude-sonnet-4-5',
    },
  ),
  const HyperVaultProvider(
    id: 'gemini',
    raw: {
      'id': 'gemini',
      'name': 'Gemini',
      'protocol': 'gemini',
      'requiresKey': true,
      'defaultModel': 'gemini-2.0-flash',
    },
  ),
  const HyperVaultProvider(
    id: 'mistral',
    raw: {
      'id': 'mistral',
      'name': 'Mistral',
      'protocol': 'openai',
      'requiresKey': true,
      'defaultModel': 'mistral-large-latest',
    },
  ),
  const HyperVaultProvider(
    id: 'ollama',
    raw: {
      'id': 'ollama',
      'name': 'Ollama',
      'protocol': 'openai',
      'optionalKey': true,
      'defaultBaseUrl': 'http://localhost:11434/v1',
      'defaultModel': 'llama3.1',
    },
  ),
  const HyperVaultProvider(
    id: 'lm_studio',
    raw: {
      'id': 'lm_studio',
      'name': 'LM Studio',
      'protocol': 'openai',
      'optionalKey': true,
      'defaultBaseUrl': 'http://localhost:1234/v1',
    },
  ),
  const HyperVaultProvider(
    id: 'custom',
    raw: {
      'id': 'custom',
      'name': 'Custom (OpenAI-compatible)',
      'protocol': 'openai',
      'optionalKey': true,
    },
  ),
];

/// Provider ids that always run on a local runtime, plus the `custom`
/// catch-all — these require an explicit base URL and get the
/// localhost-reachability caveat (PRD T-M10-08).
bool isLocalOrCustomProviderId(String id) {
  final normalized = id.toLowerCase();
  return normalized == 'ollama' ||
      normalized == 'lm_studio' ||
      normalized == 'lmstudio' ||
      normalized.startsWith('custom');
}

/// True when [url] points at the phone itself — on a phone `localhost` is
/// never the intended target for a server-driven backend (PRD T-M10-08).
bool isLocalhostUrl(String? url) {
  if (url == null) return false;
  final lower = url.toLowerCase();
  return lower.contains('localhost') || lower.contains('127.0.0.1');
}

String? providerRawString(HyperVaultProvider provider, String key) =>
    provider.raw[key] as String?;

bool providerRawBool(HyperVaultProvider provider, String key) =>
    provider.raw[key] as bool? ?? false;

/// Human-friendly label for a provider, falling back to a title-cased id
/// when the registry doesn't supply a `name`.
String providerDisplayName(HyperVaultProvider provider) {
  final name = providerRawString(provider, 'name');
  if (name != null && name.isNotEmpty) return name;
  final id = provider.id;
  if (id.isEmpty) return 'Unknown';
  return id
      .split(RegExp(r'[_-]'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
