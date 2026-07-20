/// Mirrors `validateSubdomain` in the hypervault repo's `lib/domains.ts` so
/// the claim button can disable before any request (spec T-M13-03). The
/// server re-validates regardless — this is a UX shortcut, not the source of
/// truth.
class SubdomainValidation {
  final bool ok;
  final String? name;
  final String? error;

  const SubdomainValidation.valid(String this.name) : ok = true, error = null;
  const SubdomainValidation.invalid(String this.error)
    : ok = false,
      name = null;
}

final _subdomainRe = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');

const _reservedSubdomains = {
  'www',
  'app',
  'api',
  'mcp',
  'mail',
  'mx',
  'auth',
  'beta',
  'alpha',
  'admin',
  'root',
  'dashboard',
  'vault',
  'help',
  'support',
  'docs',
  'blog',
  'status',
  'dev',
  'staging',
  'test',
  'assets',
  'cdn',
  'static',
  'hypervault',
  'billing',
  'login',
  'signup',
  'graph',
  'wss',
  'secure',
};

const _reservedPrefixes = ['www'];

SubdomainValidation validateSubdomain(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.length < 2) {
    return const SubdomainValidation.invalid('Pick at least 2 characters.');
  }
  if (normalized.length > 63) {
    return const SubdomainValidation.invalid(
      'Subdomains max out at 63 characters.',
    );
  }
  if (!_subdomainRe.hasMatch(normalized)) {
    return const SubdomainValidation.invalid(
      'Use only lowercase letters, numbers, and hyphens (no leading/trailing hyphen).',
    );
  }
  if (_reservedSubdomains.contains(normalized) ||
      _reservedPrefixes.any((prefix) => normalized.startsWith(prefix))) {
    return SubdomainValidation.invalid('"$normalized" is reserved.');
  }
  return SubdomainValidation.valid(normalized);
}
