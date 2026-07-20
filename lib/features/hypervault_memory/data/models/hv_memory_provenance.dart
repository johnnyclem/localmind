/// Provenance receipt for a memory: the commit that last touched it, when,
/// and by whom (you / an agent key / the system). See
/// docs/mobile/prd/api-contract.md `provenance` fields.
class HvMemoryProvenance {
  final String commitId;
  final String message;
  final String authorKind;
  final String? authorKeyPrefix;
  final DateTime? committedAt;

  const HvMemoryProvenance({
    required this.commitId,
    required this.message,
    required this.authorKind,
    this.authorKeyPrefix,
    this.committedAt,
  });

  /// Provenance is returned as `unknown`/possibly-absent by the API — parse
  /// defensively and return null rather than throw.
  static HvMemoryProvenance? tryParse(dynamic json) {
    if (json is! Map) return null;
    final map = json.cast<String, dynamic>();
    final commitId = map['commit_id'] as String?;
    if (commitId == null) return null;
    return HvMemoryProvenance(
      commitId: commitId,
      message: map['message'] as String? ?? '',
      authorKind: map['author_kind'] as String? ?? 'user',
      authorKeyPrefix: map['author_key_prefix'] as String?,
      committedAt: DateTime.tryParse(map['committed_at'] as String? ?? ''),
    );
  }

  /// "you" / "agent hv_ab12cdef" / "system", mirroring the web copy.
  String get authorLabel {
    switch (authorKind) {
      case 'agent':
        return authorKeyPrefix != null ? 'agent $authorKeyPrefix' : 'agent';
      case 'system':
        return 'system';
      default:
        return 'you';
    }
  }
}
