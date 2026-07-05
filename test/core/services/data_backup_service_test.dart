import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/services/data_backup_service.dart';
import 'package:localmind/core/storage/entities.dart';
import 'package:localmind/features/conversations/data/models/conversation.dart';
import 'package:localmind/objectbox.g.dart';

void main() {
  test('conversation exports include the referenced folder metadata', () {
    final folder = ConversationFolderEntity(
      id: 'folder-1',
      name: 'Inbox',
      sortOrder: 3,
      createdAt: DateTime.utc(2026, 7, 5),
    );
    final otherFolder = ConversationFolderEntity(
      id: 'folder-2',
      name: 'Archive',
      sortOrder: 9,
      createdAt: DateTime.utc(2026, 7, 4),
    );
    final conversation = ConversationEntity.fromDomain(
      Conversation(
        id: 'conv-1',
        title: 'Exported Chat',
        createdAt: DateTime.utc(2026, 7, 5),
        updatedAt: DateTime.utc(2026, 7, 5),
        folderId: folder.id,
      ),
    );
    final otherConversation = ConversationEntity.fromDomain(
      Conversation(
        id: 'conv-2',
        title: 'Different Chat',
        createdAt: DateTime.utc(2026, 7, 5),
        updatedAt: DateTime.utc(2026, 7, 5),
        folderId: otherFolder.id,
      ),
    );

    final store = _FakeStore({
      ConversationEntity: _FakeBox([conversation, otherConversation]),
      MessageEntity: _FakeBox<MessageEntity>(const []),
      PersonaEntity: _FakeBox<PersonaEntity>(const []),
      SavedMessageEntity: _FakeBox<SavedMessageEntity>(const []),
      SavedMessageFolderEntity: _FakeBox<SavedMessageFolderEntity>(const []),
      ServerEntity: _FakeBox<ServerEntity>(const []),
      ConversationFolderEntity: _FakeBox([folder, otherFolder]),
    });

    final service = DataBackupService();

    final allExport =
        jsonDecode(service.exportConversationsAsJson(store))
            as Map<String, dynamic>;
    expect(
      (allExport['conversationFolders'] as List)
          .cast<Map<String, dynamic>>()
          .map((folder) => folder['id'])
          .toSet(),
      {folder.id, otherFolder.id},
    );

    final singleExport =
        jsonDecode(service.exportConversationAsJson(store, conversation.id))
            as Map<String, dynamic>;
    expect(
      (singleExport['conversationFolders'] as List)
          .cast<Map<String, dynamic>>()
          .single['id'],
      folder.id,
    );

    final filteredExport =
        jsonDecode(
              service.exportConversationsForIdsAsJson(store, {
                otherConversation.id,
              }),
            )
            as Map<String, dynamic>;
    expect(
      (filteredExport['conversationFolders'] as List)
          .cast<Map<String, dynamic>>()
          .single['id'],
      otherFolder.id,
    );
  });
}

class _FakeStore extends Fake implements Store {
  _FakeStore(this._boxes);

  final Map<Type, Object> _boxes;

  @override
  Box<T> box<T>() => _boxes[T] as Box<T>;
}

class _FakeBox<T> extends Fake implements Box<T> {
  _FakeBox(this._items);

  final List<T> _items;

  @override
  List<T> getAll() => List<T>.from(_items);
}
