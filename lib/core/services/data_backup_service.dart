import 'dart:convert';

import 'package:archive/archive.dart';

import '../models/enums.dart';
import '../storage/entities.dart';
import '../../features/chat/data/models/message.dart';
import '../../features/conversations/data/models/conversation.dart';
import '../../features/personas/data/models/persona.dart';
import '../../objectbox.g.dart';

class DataBackupService {
  Map<String, dynamic> exportAll(Store store) {
    final convBox = store.box<ConversationEntity>();
    final messageBox = store.box<MessageEntity>();
    final personaBox = store.box<PersonaEntity>();

    final conversations = convBox.getAll().map((entity) {
      final domain = entity.toDomain();
      return {
        'id': domain.id,
        'title': domain.title,
        'createdAt': domain.createdAt.toIso8601String(),
        'updatedAt': domain.updatedAt.toIso8601String(),
        'isPinned': domain.isPinned,
        'personaId': domain.personaId,
        'serverId': domain.serverId,
        'modelId': domain.modelId,
        'messageCount': domain.messageCount,
        'lastMessagePreview': domain.lastMessagePreview,
        'systemPrompt': domain.systemPrompt,
        'temperature': domain.temperature,
        'topP': domain.topP,
        'maxTokens': domain.maxTokens,
        'contextLength': domain.contextLength,
        'mcpEnabled': domain.mcpEnabled,
        'smartReplies': domain.smartReplies,
        'smartRepliesLastMessageId': domain.smartRepliesLastMessageId,
        'folderId': domain.folderId,
      };
    }).toList();

    final messages = messageBox.getAll().map((entity) {
      final message = entity.toDomain();
      return {
        'id': message.id,
        'conversationId': message.conversationId,
        'role': message.role.name,
        'content': message.content,
        'createdAt': message.createdAt.toIso8601String(),
        'status': message.status.name,
        'modelId': message.modelId,
        'tokenCount': message.tokenCount,
        'errorMessage': message.errorMessage,
        'attachmentPaths': message.attachmentPaths,
        'generationTimeMs': message.generationTimeMs,
        'reasoningContent': message.reasoningContent,
        'toolCallId': message.toolCallId,
        'isProcessing': message.isProcessing,
        'toolSessionId': message.toolSessionId,
        'variantGroupId': message.variantGroupId,
        'variantIndex': message.variantIndex,
        'threadOrder': message.threadOrder,
        'isActiveVariant': message.isActiveVariant,
      };
    }).toList();

    final personas = personaBox
        .getAll()
        .where((entity) => !entity.isBuiltIn)
        .map((entity) {
          final persona = entity.toDomain();
          return {
            'id': persona.id,
            'name': persona.name,
            'emoji': persona.emoji,
            'systemPrompt': persona.systemPrompt,
            'description': persona.description,
            'isBuiltIn': persona.isBuiltIn,
            'createdAt': persona.createdAt.toIso8601String(),
            'updatedAt': persona.updatedAt.toIso8601String(),
            'category': persona.category,
            'preferredParams': persona.preferredParams,
          };
        })
        .toList();

    return {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'conversations': conversations,
      'messages': messages,
      'personas': personas,
    };
  }

  Map<String, dynamic> exportConversations(Store store) {
    final all = exportAll(store);
    return {
      'version': 2,
      'type': 'conversations',
      'exportedAt': all['exportedAt'],
      'conversations': all['conversations'],
      'messages': all['messages'],
    };
  }

  Map<String, dynamic> exportPersonas(Store store) {
    final all = exportAll(store);
    return {
      'version': 2,
      'type': 'personas',
      'exportedAt': all['exportedAt'],
      'personas': all['personas'],
    };
  }

  Map<String, dynamic> exportSettings(String settingsJson) {
    return {
      'version': 2,
      'type': 'settings',
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': jsonDecode(settingsJson),
    };
  }

  String exportConversationsAsJson(Store store) =>
      const JsonEncoder.withIndent('  ').convert(exportConversations(store));

  String exportPersonasAsJson(Store store) =>
      const JsonEncoder.withIndent('  ').convert(exportPersonas(store));

  String exportSettingsAsJson(String settingsJson) =>
      const JsonEncoder.withIndent('  ').convert(exportSettings(settingsJson));

  List<int> exportAllZip(Store store, String settingsJson) {
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'conversations.json',
          0,
          utf8.encode(exportConversationsAsJson(store)),
        ),
      )
      ..addFile(
        ArchiveFile(
          'personas.json',
          0,
          utf8.encode(exportPersonasAsJson(store)),
        ),
      )
      ..addFile(
        ArchiveFile(
          'settings.json',
          0,
          utf8.encode(exportSettingsAsJson(settingsJson)),
        ),
      );
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('Failed to encode backup ZIP');
    }
    return encoded;
  }

  String exportAllAsJson(Store store) {
    return const JsonEncoder.withIndent('  ').convert(exportAll(store));
  }

  Future<void> importFromJson(Store store, String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid backup format');
    }

    await store.runInTransactionAsync(TxMode.write, (store, data) {
      final convBox = store.box<ConversationEntity>();
      final messageBox = store.box<MessageEntity>();
      final personaBox = store.box<PersonaEntity>();

      final personas = data['personas'];
      if (personas is List) {
        for (final item in personas) {
          if (item is! Map) continue;
          final persona = Persona(
            id: item['id'] as String,
            name: item['name'] as String,
            emoji: item['emoji'] as String? ?? '🤖',
            systemPrompt: item['systemPrompt'] as String? ?? '',
            description: item['description'] as String?,
            isBuiltIn: item['isBuiltIn'] as bool? ?? false,
            createdAt: DateTime.parse(item['createdAt'] as String),
            updatedAt: DateTime.parse(item['updatedAt'] as String),
            category: item['category'] as String?,
            preferredParams: item['preferredParams'] is Map
                ? Map<String, dynamic>.from(item['preferredParams'] as Map)
                : null,
          );
          final query =
              personaBox.query(PersonaEntity_.id.equals(persona.id)).build();
          final existing = query.findFirst();
          query.close();
          final entity = PersonaEntity.fromDomain(persona);
          if (existing != null) entity.internalId = existing.internalId;
          personaBox.put(entity);
        }
      }

      final conversations = data['conversations'];
      if (conversations is List) {
        for (final item in conversations) {
          if (item is! Map) continue;
          final conversation = Conversation(
            id: item['id'] as String,
            title: item['title'] as String? ?? 'Imported Chat',
            createdAt: DateTime.parse(item['createdAt'] as String),
            updatedAt: DateTime.parse(item['updatedAt'] as String),
            isPinned: item['isPinned'] as bool? ?? false,
            personaId: item['personaId'] as String?,
            serverId: item['serverId'] as String?,
            modelId: item['modelId'] as String?,
            messageCount: item['messageCount'] as int? ?? 0,
            lastMessagePreview: item['lastMessagePreview'] as String?,
            systemPrompt: item['systemPrompt'] as String?,
            temperature: (item['temperature'] as num?)?.toDouble(),
            topP: (item['topP'] as num?)?.toDouble(),
            maxTokens: item['maxTokens'] as int?,
            contextLength: item['contextLength'] as int?,
            mcpEnabled: item['mcpEnabled'] as bool?,
            smartReplies: item['smartReplies'] is List
                ? List<String>.from(item['smartReplies'] as List)
                : null,
            smartRepliesLastMessageId:
                item['smartRepliesLastMessageId'] as String?,
            folderId: item['folderId'] as String?,
          );
          final query =
              convBox.query(ConversationEntity_.id.equals(conversation.id)).build();
          final existing = query.findFirst();
          query.close();
          final entity = ConversationEntity.fromDomain(conversation);
          if (existing != null) entity.internalId = existing.internalId;
          convBox.put(entity);
        }
      }

      final messages = data['messages'];
      if (messages is List) {
        for (final item in messages) {
          if (item is! Map) continue;
          final convQuery = convBox
              .query(ConversationEntity_.id.equals(item['conversationId'] as String))
              .build();
          final convEntity = convQuery.findFirst();
          convQuery.close();
          if (convEntity == null) continue;

          final message = Message(
            id: item['id'] as String,
            conversationId: item['conversationId'] as String,
            role: MessageRole.values.byName(item['role'] as String? ?? 'user'),
            content: item['content'] as String? ?? '',
            createdAt: DateTime.parse(item['createdAt'] as String),
            status: MessageStatus.values.byName(
              item['status'] as String? ?? 'complete',
            ),
            modelId: item['modelId'] as String?,
            tokenCount: item['tokenCount'] as int?,
            errorMessage: item['errorMessage'] as String?,
            attachmentPaths: item['attachmentPaths'] is List
                ? List<String>.from(item['attachmentPaths'] as List)
                : null,
            generationTimeMs: item['generationTimeMs'] as int?,
            reasoningContent: item['reasoningContent'] as String?,
            toolCallId: item['toolCallId'] as String?,
            isProcessing: item['isProcessing'] as bool? ?? false,
            toolSessionId: item['toolSessionId'] as String?,
            variantGroupId: item['variantGroupId'] as String?,
            variantIndex: item['variantIndex'] as int? ?? 0,
            threadOrder: item['threadOrder'] as int? ?? 0,
            isActiveVariant: item['isActiveVariant'] as bool? ?? true,
          );

          final entity = MessageEntity.fromDomain(message)
            ..conversation.target = convEntity;
          final query = messageBox.query(MessageEntity_.id.equals(message.id)).build();
          final existing = query.findFirst();
          query.close();
          if (existing != null) entity.internalId = existing.internalId;
          messageBox.put(entity);
        }
      }
    }, decoded);
  }

  Future<void> importZip(Store store, List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      if (file.isFile) {
        await importFromJson(store, utf8.decode(file.content));
      }
    }
  }
}
