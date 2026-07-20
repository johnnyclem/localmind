/// One line of a diff hunk: `add` (green +), `del` (red -), or `ctx` (muted,
/// unchanged context).
class HvDiffLine {
  final String kind;
  final String text;

  const HvDiffLine({required this.kind, required this.text});

  bool get isAdd => kind == 'add';
  bool get isDel => kind == 'del';

  factory HvDiffLine.fromJson(Map<String, dynamic> json) {
    return HvDiffLine(
      kind: json['kind'] as String? ?? 'ctx',
      text: json['text'] as String? ?? '',
    );
  }
}

class HvDiffHunk {
  final int oldStart;
  final int oldLines;
  final int newStart;
  final int newLines;
  final List<HvDiffLine> lines;

  const HvDiffHunk({
    required this.oldStart,
    required this.oldLines,
    required this.newStart,
    required this.newLines,
    required this.lines,
  });

  factory HvDiffHunk.fromJson(Map<String, dynamic> json) {
    return HvDiffHunk(
      oldStart: (json['oldStart'] as num?)?.toInt() ?? 0,
      oldLines: (json['oldLines'] as num?)?.toInt() ?? 0,
      newStart: (json['newStart'] as num?)?.toInt() ?? 0,
      newLines: (json['newLines'] as num?)?.toInt() ?? 0,
      lines: ((json['lines'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvDiffLine.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// A line-level text diff (jsdiff `structuredPatch` under the hood). Empty
/// [hunks] with `oversize: false` means "no content change — title or tags
/// only"; `oversize: true` means "content replaced — too large to diff line
/// by line".
class HvTextDiff {
  final List<HvDiffHunk> hunks;
  final bool oversize;

  const HvTextDiff({required this.hunks, required this.oversize});

  factory HvTextDiff.fromJson(Map<String, dynamic> json) {
    return HvTextDiff(
      hunks: ((json['hunks'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => HvDiffHunk.fromJson(e.cast<String, dynamic>()))
          .toList(),
      oversize: json['oversize'] as bool? ?? false,
    );
  }
}

/// Response of `GET /api/mind/diff?...&memory_id=` — the single-memory diff
/// between two refs.
class HvMemoryDiffResult {
  final String memoryId;
  final String? titleFrom;
  final String? titleTo;
  final List<String> tagsAdded;
  final List<String> tagsRemoved;
  final String status;
  final HvTextDiff diff;

  const HvMemoryDiffResult({
    required this.memoryId,
    this.titleFrom,
    this.titleTo,
    required this.tagsAdded,
    required this.tagsRemoved,
    required this.status,
    required this.diff,
  });

  factory HvMemoryDiffResult.fromJson(Map<String, dynamic> json) {
    return HvMemoryDiffResult(
      memoryId: json['memory_id'] as String? ?? '',
      titleFrom: json['title_from'] as String?,
      titleTo: json['title_to'] as String?,
      tagsAdded: ((json['tags_added'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      tagsRemoved: ((json['tags_removed'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      status: json['status'] as String? ?? 'changed',
      diff: HvTextDiff.fromJson(
        (json['diff'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
