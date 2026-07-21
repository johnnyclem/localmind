/// A single edge from `GET /api/connections`'s `connections[]` array (mobile
/// PRD M4, T-M4-02/05) — artifact-to-artifact only in v1; `memory_links` and
/// `memory_artifact_links` are out of scope here (see
/// hypervault-web `docs/mobile/prd/04-vault-graph.md`).
///
/// `a_id`/`b_id` are the artifacts' database ids. The mobile `/api/artifacts`
/// list (see `lib/features/vault/data/models/artifact.dart`) does not
/// currently return an `id` field, only `slug` — so those ids can't be
/// resolved against the loaded artifact list today. Parsing here is
/// deliberately defensive about the field name (`a_id`/`aId`/`source`/
/// `from`/`a_slug` and the `b_*` equivalents) so that if the backend ever
/// starts returning slugs, or an `id` field lands on `/api/artifacts`, edges
/// start resolving without any change to this model.
class VaultConnection {
  final String id;
  final String aId;
  final String bId;

  /// `"manual"` (solid edge) or `"auto"` (dashed edge). Anything else is
  /// treated as manual, matching the web's `kind !== "auto"` check.
  final String kind;
  final DateTime? createdAt;

  const VaultConnection({
    required this.id,
    required this.aId,
    required this.bId,
    required this.kind,
    this.createdAt,
  });

  bool get isManual => kind.toLowerCase() != 'auto';

  static String _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return '';
  }

  factory VaultConnection.fromJson(Map<String, dynamic> json) {
    return VaultConnection(
      id: _pick(json, const ['id']),
      aId: _pick(json, const ['a_id', 'aId', 'source', 'from', 'a_slug']),
      bId: _pick(json, const ['b_id', 'bId', 'target', 'to', 'b_slug']),
      kind: (json['kind'] as String?)?.trim().toLowerCase() ?? 'manual',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
