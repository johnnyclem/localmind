/// Result of `POST /api/import` — see docs/mobile/prd/api-contract.md and
/// docs/mobile/prd/12-import-history.md in the hypervault repo.
class HvImportResult {
  final String? platform;
  final int imported;
  final int skipped;
  final List<String> messages;
  final String message;

  const HvImportResult({
    this.platform,
    required this.imported,
    required this.skipped,
    required this.messages,
    required this.message,
  });

  factory HvImportResult.fromJson(Map<String, dynamic> json) {
    return HvImportResult(
      platform: json['platform'] as String?,
      imported: (json['imported'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      messages: ((json['messages'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      message: json['message'] as String? ?? '',
    );
  }
}
