/// The wire format HyperVault uses for chat context/history everywhere
/// (`POST /api/chat`, `POST /api/chat/context`, conversation messages).
/// Mirrors the `CanonicalMessage`/`CanonicalAttachment`/`CanonicalRole`
/// types in `docs/mobile/prd/api-contract.md`.
enum CanonicalRole { system, user, assistant, tool }

CanonicalRole canonicalRoleFromString(String value) {
  switch (value) {
    case 'system':
      return CanonicalRole.system;
    case 'assistant':
      return CanonicalRole.assistant;
    case 'tool':
      return CanonicalRole.tool;
    case 'user':
    default:
      return CanonicalRole.user;
  }
}

extension CanonicalRoleJson on CanonicalRole {
  String get wireValue => name;
}

class CanonicalAttachment {
  final String name;
  final String? mimeType;
  final int? size;
  final String? extractedText;

  const CanonicalAttachment({
    required this.name,
    this.mimeType,
    this.size,
    this.extractedText,
  });

  factory CanonicalAttachment.fromJson(Map<String, dynamic> json) =>
      CanonicalAttachment(
        name: json['name'] as String? ?? '',
        mimeType: json['mime_type'] as String?,
        size: json['size'] as int?,
        extractedText: json['extracted_text'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (mimeType != null) 'mime_type': mimeType,
    if (size != null) 'size': size,
    if (extractedText != null) 'extracted_text': extractedText,
  };
}

class CanonicalMessage {
  final CanonicalRole role;
  final String content;
  final List<CanonicalAttachment> attachments;
  final String? model;
  final DateTime? createdAt;

  const CanonicalMessage({
    required this.role,
    required this.content,
    this.attachments = const [],
    this.model,
    this.createdAt,
  });

  factory CanonicalMessage.fromJson(Map<String, dynamic> json) =>
      CanonicalMessage(
        role: canonicalRoleFromString(json['role'] as String? ?? 'user'),
        content: json['content'] as String? ?? '',
        attachments: ((json['attachments'] as List?) ?? const [])
            .map((e) => CanonicalAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
        model: json['model'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'role': role.wireValue,
    'content': content,
    'attachments': attachments.map((e) => e.toJson()).toList(),
    if (model != null) 'model': model,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}
