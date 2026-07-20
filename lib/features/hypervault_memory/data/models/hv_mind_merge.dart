/// Change tally from a successful (non-conflicting) `POST /api/mind/merge`.
class HvMergeCounts {
  final int created;
  final int updated;
  final int deleted;

  const HvMergeCounts({this.created = 0, this.updated = 0, this.deleted = 0});

  factory HvMergeCounts.fromJson(Map<String, dynamic> json) {
    return HvMergeCounts(
      created: (json['created'] as num?)?.toInt() ?? 0,
      updated: (json['updated'] as num?)?.toInt() ?? 0,
      deleted: (json['deleted'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Response of a clean `POST /api/mind/merge` (200). A conflicting merge
/// returns 409 instead — see [HypervaultMindService.merge] doc comment: the
/// shared [HyperVaultApiClient] normalizes every non-2xx body down to
/// `{status, error}`, so the 409 `conflicts[]` payload isn't recoverable
/// here without extending that client (noted for the integration pass).
class HvMergeOutcome {
  final String? commitId;
  final HvMergeCounts merged;
  final int linksChanged;
  final String message;

  const HvMergeOutcome({
    this.commitId,
    required this.merged,
    required this.linksChanged,
    required this.message,
  });

  factory HvMergeOutcome.fromJson(Map<String, dynamic> json) {
    return HvMergeOutcome(
      commitId: json['commit_id'] as String?,
      merged: HvMergeCounts.fromJson(
        (json['merged'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      linksChanged: (json['links_changed'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}
