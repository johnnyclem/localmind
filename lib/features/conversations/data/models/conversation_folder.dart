class ConversationFolder {
  final String id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;

  ConversationFolder({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    required this.createdAt,
  });

  ConversationFolder copyWith({
    String? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ConversationFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
