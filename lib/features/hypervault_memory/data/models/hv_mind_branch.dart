/// One row of `GET /api/mind/branches` — a fork of the mind, with the
/// number of memories currently alive on it.
class HvMindBranch {
  final String id;
  final String name;
  final bool isDefault;
  final String? headCommitId;
  final DateTime? createdAt;
  final int memoryCount;

  const HvMindBranch({
    required this.id,
    required this.name,
    required this.isDefault,
    this.headCommitId,
    this.createdAt,
    required this.memoryCount,
  });

  factory HvMindBranch.fromJson(Map<String, dynamic> json) {
    return HvMindBranch(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'main',
      isDefault: json['is_default'] as bool? ?? false,
      headCommitId: json['head_commit_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      memoryCount: (json['memory_count'] as num?)?.toInt() ?? 0,
    );
  }
}
