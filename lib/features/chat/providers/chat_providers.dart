import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../../../core/logger/app_logger.dart';
import '../../../core/services/message_save_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import 'package:localmind/features/conversations/providers/conversation_providers.dart'
    as conv;
import 'package:localmind/features/models/data/models/model_info.dart';
import 'package:localmind/features/personas/providers/personas_providers.dart';
import 'package:localmind/features/servers/providers/server_providers.dart';
import './chat_mcp_providers.dart';

import '../../../core/models/enums.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/storage_providers.dart';
import '../../on_device/providers/on_device_providers.dart';
import '../../on_device/data/on_device_chat_service.dart';
import '../../../core/storage/entities.dart';
import '../../../objectbox.g.dart';
import '../../conversations/data/models/conversation.dart';
import '../data/chat_service.dart';
import '../data/models/chat_parameters.dart';
import '../data/models/message.dart' hide ToolCallData;
import '../data/smart_reply_service.dart';
import '../data/tools/tool_definition.dart';
import '../data/tools/tool_execution_loop.dart';
import '../data/tools/adapters/tool_transport_adapter.dart' show ParsedToolCall;
import '../../../core/providers/chat_background_service_provider.dart';
import './tooling_providers.dart';

final selectedModelProvider =
    NotifierProvider<SelectedModelNotifier, ModelInfo?>(() {
      return SelectedModelNotifier();
    });

class SelectedModelNotifier extends Notifier<ModelInfo?> {
  @override
  ModelInfo? build() => null;

  void setModel(ModelInfo? model) {
    state = model;
  }

  void clear() {
    state = null;
  }
}

final autoSelectFirstLoadedModelProvider = FutureProvider<void>((ref) async {
  final activeServer = ref.watch(activeServerProvider);
  final status = ref.watch(connectionStatusProvider);

  if (activeServer == null) {
    // Use await Future.value() to defer outside the current build frame.
    await Future.value();
    ref.read(selectedModelProvider.notifier).clear();
    return;
  }

  // If server is not connected, we can't fetch loaded models
  if (status != ConnectionStatus.connected) return;

  final selectedModel = ref.read(selectedModelProvider);

  // If a model is selected but belongs to a different server, clear it
  if (selectedModel != null && selectedModel.serverId != activeServer.id) {
    await Future.value();
    ref.read(selectedModelProvider.notifier).clear();
    // Continue to try auto-selecting for the new server
  } else if (selectedModel != null) {
    // Already have a valid model selected for this server
    return;
  }

  // Only auto-select for servers that support listing running models
  if (activeServer.type == ServerType.openRouter ||
      activeServer.type == ServerType.openAICompatible) {
    return;
  }

  try {
    final Set<String> loadedModels;
    if (activeServer.type == ServerType.onDevice) {
      final engine = ref.watch(onDeviceEngineProvider);
      loadedModels = engine.loadedModelId != null
          ? {engine.loadedModelId!}
          : {};
    } else {
      final apiService = ref.read(serverApiServiceProvider);
      loadedModels = await apiService.fetchRunningModels(activeServer);
    }

    if (loadedModels.isEmpty) return;

    final availableModels = await ref.read(
      availableModelsProvider(activeServer.id).future,
    );
    if (availableModels.isEmpty) return;

    final typedModels = availableModels.cast<ModelInfo>();

    // For LM Studio, often the 'key' is what's used. For Ollama, it's 'name'.
    // ServerApiService parses these into the same ID field.
    final firstLoadedModel = typedModels
        .where((m) => loadedModels.contains(m.id))
        .firstOrNull;

    if (firstLoadedModel != null) {
      ref.read(selectedModelProvider.notifier).setModel(firstLoadedModel);
    }
  } catch (e) {
    // Silently fail auto-selection
  }
});

final isStreamingProvider = NotifierProvider<IsStreamingNotifier, bool>(() {
  return IsStreamingNotifier();
});

class IsStreamingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setStreaming(bool streaming) {
    state = streaming;
  }
}

class ModelLoadingState {
  final bool isLoading;
  final String? modelId;
  final double? progress;

  const ModelLoadingState({
    this.isLoading = false,
    this.modelId,
    this.progress,
  });

  ModelLoadingState copyWith({
    bool? isLoading,
    String? modelId,
    double? progress,
  }) {
    return ModelLoadingState(
      isLoading: isLoading ?? this.isLoading,
      modelId: modelId ?? this.modelId,
      progress: progress ?? this.progress,
    );
  }
}

final modelLoadingProvider =
    NotifierProvider<ModelLoadingNotifier, ModelLoadingState>(() {
      return ModelLoadingNotifier();
    });

class ModelLoadingNotifier extends Notifier<ModelLoadingState> {
  @override
  ModelLoadingState build() => const ModelLoadingState();

  void setLoading(String modelId, {double? progress}) {
    state = ModelLoadingState(
      isLoading: true,
      modelId: modelId,
      progress: progress,
    );
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void setLoaded() {
    state = const ModelLoadingState();
  }
}

final modelThinkingProvider = Provider<bool>((ref) {
  return ref.watch(isStreamingProvider);
});

final chatParamsProvider = Provider<ChatParameters>((ref) {
  final settings = ref.watch(settingsProvider);
  final activeConv = ref.watch(conv.activeConversationProvider);

  // Start with app-level defaults
  double temperature = settings.temperature;
  double topP = settings.topP;
  int maxTokens = settings.maxTokens;
  int contextLength = settings.contextLength;

  // Apply per-conversation overrides if they exist
  if (activeConv?.temperature != null) {
    temperature = activeConv!.temperature!;
  }
  if (activeConv?.topP != null) {
    topP = activeConv!.topP!;
  }
  if (activeConv?.maxTokens != null) {
    maxTokens = activeConv!.maxTokens!;
  }
  if (activeConv?.contextLength != null) {
    contextLength = activeConv!.contextLength!;
  }

  String? systemPrompt;
  if (activeConv?.personaId != null) {
    final personaId = activeConv!.personaId;
    try {
      final personasAsync = ref.read(personasNotifierProvider);
      final personas = personasAsync.value ?? [];
      final persona = personas.firstWhere(
        (p) => p.id == personaId,
        orElse: () => throw Exception('Persona not found'),
      );
      systemPrompt = persona.systemPrompt;
      if (persona.preferredParams != null) {
        final params = persona.preferredParams as Map<String, dynamic>;
        if (params['temperature'] != null) {
          temperature = (params['temperature'] as num).toDouble();
        }
        if (params['topP'] != null) topP = (params['topP'] as num).toDouble();
        if (params['maxTokens'] != null) {
          maxTokens = (params['maxTokens'] as num).toInt();
        }
      }
    } catch (_) {}
  }

  return ChatParameters(
    temperature: temperature,
    topP: topP,
    maxTokens: maxTokens,
    contextLength: contextLength,
    systemPrompt: systemPrompt,
  );
});

final chatServiceProvider = Provider<ChatService?>((ref) {
  final server = ref.watch(activeServerProvider);
  if (server == null) {
    return null;
  }
  final ChatService service;
  if (server.type == ServerType.onDevice) {
    final gemmaService = ref.read(onDeviceGemmaServiceProvider);
    service = ChatService.forServer(
      server.type,
      ref.read(dioProvider),
      onDeviceGemma: gemmaService,
    );
  } else {
    service = ChatService.forServer(server.type, ref.read(dioProvider));
  }

  ref.onDispose(() {
    final s = service;
    if (s is OnDeviceChatService) {
      s.dispose();
    }
  });

  return service;
});

final smartReplyServiceProvider = Provider<SmartReplyService>((ref) {
  final service = SmartReplyService();
  ref.onDispose(() => service.dispose());
  return service;
});

final smartRepliesProvider = FutureProvider<List<String>>((ref) async {
  final isStreaming = ref.watch(chatProvider.select((s) => s.isStreaming));
  final settings = ref.watch(settingsProvider);

  if (isStreaming) return [];

  final messages = ref.watch(chatProvider.select((s) => s.messages));
  if (messages.isEmpty) return [];

  final lastMessage = messages.last;
  if (lastMessage.role != MessageRole.assistant ||
      lastMessage.status != MessageStatus.complete) {
    return [];
  }

  // Load saved replies if they exist for the current last message
  final activeConv = ref.watch(conv.activeConversationProvider);
  if (activeConv != null &&
      activeConv.smartRepliesLastMessageId == lastMessage.id &&
      activeConv.smartReplies != null &&
      activeConv.smartReplies!.isNotEmpty) {
    return activeConv.smartReplies!;
  }

  List<String> suggestions = [];

  if (settings.smartReplyEnabled) {
    final server = ref.watch(activeServerProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final chatParams = ref.watch(chatParamsProvider);
    final chatService = ref.watch(chatServiceProvider);

    if (server != null && chatService != null && selectedModel != null) {
      final service = ref.read(smartReplyServiceProvider);
      suggestions = await service.suggestRepliesWithLLM(
        chatService: chatService,
        server: server,
        modelId: selectedModel.id,
        messages: messages,
        params: chatParams,
      );
      if (!ref.mounted) return [];
    }
  }

  if (suggestions.isEmpty) {
    final service = ref.read(smartReplyServiceProvider);
    suggestions = service.getFallbackReplies(lastMessage.content);
  }

  // Save the replies to the conversation database
  if (activeConv != null && suggestions.isNotEmpty) {
    Future.microtask(() {
      if (ref.mounted) {
        ref
            .read(conv.conversationsProvider.notifier)
            .updateSmartReplies(activeConv.id, suggestions, lastMessage.id);
      }
    });
  }

  return suggestions;
});

class PendingToolApproval {
  final ParsedToolCall toolCall;
  final Completer<bool> completer;

  PendingToolApproval({required this.toolCall, required this.completer});
}

class ChatState {
  final List<Message> messages;
  final bool isStreaming;
  final bool isLoading;
  final String? errorMessage;
  final Message? streamingMessage;
  final PendingToolApproval? pendingToolApproval;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.isLoading = false,
    this.errorMessage,
    this.streamingMessage,
    this.pendingToolApproval,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isStreaming,
    bool? isLoading,
    String? errorMessage,
    Message? streamingMessage,
    PendingToolApproval? pendingToolApproval,
    bool clearError = false,
    bool clearStreaming = false,
    bool clearPendingApproval = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      streamingMessage: clearStreaming
          ? null
          : (streamingMessage ?? this.streamingMessage),
      pendingToolApproval: clearPendingApproval
          ? null
          : (pendingToolApproval ?? this.pendingToolApproval),
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});

class ChatNotifier extends Notifier<ChatState> {
  static const _checkpointChunkThreshold = 20;
  static const _checkpointTimeThreshold = Duration(seconds: 2);

  StreamSubscription<ChatResponse>? _streamSubscription;
  Timer? _uiUpdateTimer;
  Message? _latestStreamingMessage;
  String? _currentConversationId;
  int _chunkCount = 0;
  DateTime? _lastCheckpointTime;
  int _lastSavedContentLength = 0;
  int _lastSavedReasoningLength = 0;

  /// Batches checkpoint saves off the UI thread during streaming.
  MessageSaveService? _saveService;

  void approveTool(bool approved) {
    final pending = state.pendingToolApproval;
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.complete(approved);
    }
  }

  void _clearPendingApproval() {
    final pending = state.pendingToolApproval;
    if (pending != null) {
      if (!pending.completer.isCompleted) {
        pending.completer.complete(false);
      }
      state = state.copyWith(clearPendingApproval: true);
    }
  }

  @override
  ChatState build() {
    final db = ref.read(databaseProvider);
    _saveService = MessageSaveService(db);
    ref.onDispose(() {
      _uiUpdateTimer?.cancel();
      _streamSubscription?.cancel();
      _saveService?.dispose();
      final pending = state.pendingToolApproval;
      if (pending != null && !pending.completer.isCompleted) {
        pending.completer.complete(false);
      }
    });
    return const ChatState();
  }

  Future<void> loadConversation(Conversation conversation) async {
    await cancelStream();
    _currentConversationId = conversation.id;
    ref.read(smartReplyServiceProvider).reset();
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearError: true,
    );

    try {
      final db = ref.read(databaseProvider);

      final messages = await db.store.runInTransactionAsync(
        TxMode.write,
        _loadMessagesInBackground,
        conversation.id,
      );

      state = ChatState(messages: messages, isLoading: false);
      ref
          .read(conv.activeConversationProvider.notifier)
          .setActiveConversation(conversation);

      // Sync MCP config for this chat
      ref
          .read(chatMcpConfigProvider.notifier)
          .setEnabled(conversation.mcpEnabled ?? true);
    } catch (e, stackTrace) {
      Log.fatal(error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load conversation: $e',
      );
    }
  }

  static List<Message> _loadMessagesInBackground(
    Store store,
    String conversationId,
  ) {
    final convBox = store.box<ConversationEntity>();
    final messageBox = store.box<MessageEntity>();

    final convQuery = convBox
        .query(ConversationEntity_.id.equals(conversationId))
        .build();
    final convEntity = convQuery.findFirst();
    convQuery.close();

    List<Message> messages = [];

    if (convEntity != null) {
      final relatedEntities = convEntity.messages;
      if (relatedEntities.isNotEmpty) {
        messages = relatedEntities.map((e) => e.toDomain()).toList();
      } else {
        final query = messageBox
            .query(MessageEntity_.conversationUid.equals(conversationId))
            .build();
        final manualEntities = query.find();
        query.close();

        if (manualEntities.isNotEmpty) {
          for (final e in manualEntities) {
            e.conversation.target = convEntity;
            messageBox.put(e);
          }
          messages = manualEntities.map((e) => e.toDomain()).toList();
        }
      }
    } else {
      final query = messageBox
          .query(MessageEntity_.conversationUid.equals(conversationId))
          .build();
      final entities = query.find();
      query.close();
      messages = entities.map((e) => e.toDomain()).toList();
    }

    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> startNewConversation() async {
    await cancelStream();
    _currentConversationId = null;
    ref.read(smartReplyServiceProvider).reset();
    state = const ChatState();
    ref
        .read(conv.activeConversationProvider.notifier)
        .setActiveConversation(null);

    // Sync MCP config for new chat
    final settings = ref.read(settingsProvider);
    ref
        .read(chatMcpConfigProvider.notifier)
        .setEnabled(settings.newChatMcpEnabled);
  }

  String generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return [
          bytes.sublist(0, 4),
          bytes.sublist(4, 6),
          bytes.sublist(6, 8),
          bytes.sublist(8, 10),
          bytes.sublist(10, 16),
        ]
        .map((b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join())
        .join('-');
  }

  bool _shouldCheckpointSave(Message message) {
    final now = DateTime.now();
    final contentLength = message.content.length;
    final reasoningLength = message.reasoningContent?.length ?? 0;

    final hasNewContent =
        contentLength > _lastSavedContentLength ||
        reasoningLength > _lastSavedReasoningLength;

    if (!hasNewContent) return false;

    final meetsChunkThreshold = _chunkCount >= _checkpointChunkThreshold;

    final meetsTimeThreshold =
        _lastCheckpointTime != null &&
        now.difference(_lastCheckpointTime!) >= _checkpointTimeThreshold;

    return meetsChunkThreshold || meetsTimeThreshold;
  }

  void _resetCheckpointMetrics() {
    _chunkCount = 0;
    _lastCheckpointTime = DateTime.now();
  }

  void _updateSavedMetrics(Message message) {
    _lastSavedContentLength = message.content.length;
    _lastSavedReasoningLength = message.reasoningContent?.length ?? 0;
  }

  Future<void> checkpointStreamingMessage({bool flush = false}) async {
    final latest = _latestStreamingMessage ?? state.streamingMessage;
    if (latest == null) return;

    _saveService?.enqueue(latest);
    _updateSavedMetrics(latest);
    _resetCheckpointMetrics();

    if (flush) {
      await _saveService?.flush();
    }
  }

  void _replaceMessageInState(Message message, {bool clearStreaming = false}) {
    final messageIndex = state.messages.indexWhere((m) => m.id == message.id);
    if (messageIndex == -1) {
      state = state.copyWith(
        streamingMessage: clearStreaming ? null : message,
        clearStreaming: clearStreaming,
      );
      return;
    }

    final updatedMessages = List<Message>.from(state.messages);
    updatedMessages[messageIndex] = message;
    state = state.copyWith(
      messages: updatedMessages,
      streamingMessage: clearStreaming ? null : message,
      clearStreaming: clearStreaming,
    );
  }

  Future<void> sendMessage(String content, {List<File>? attachments}) async {
    final server = ref.read(activeServerProvider);
    final selectedModel = ref.read(selectedModelProvider);
    final chatParams = ref.read(chatParamsProvider);
    final chatService = ref.read(chatServiceProvider);
    final settings = ref.read(settingsProvider);

    if (server == null) {
      state = state.copyWith(errorMessage: 'No server connected');
      return;
    }

    if (content.trim().isEmpty) return;

    if (_currentConversationId == null) {
      final server = ref.read(activeServerProvider);
      final selectedModel = ref.read(selectedModelProvider);
      final selectedPersona = ref.read(selectedPersonaProvider);
      final conversation = await ref
          .read(conv.conversationsProvider.notifier)
          .createConversation(
            title: content.length > 50
                ? '${content.substring(0, 50)}...'
                : content,
            serverId: server?.id,
            modelId: selectedModel?.id,
            personaId: selectedPersona?.id,
            systemPrompt: selectedPersona?.systemPrompt,
            mcpEnabled: settings.newChatMcpEnabled,
          );
      _currentConversationId = conversation.id;
      ref
          .read(conv.activeConversationProvider.notifier)
          .setActiveConversation(conversation);

      // Sync MCP config for the newly created chat
      ref
          .read(chatMcpConfigProvider.notifier)
          .setEnabled(settings.newChatMcpEnabled);

      // Clear preselected persona after it's applied to the new conversation
      ref.read(selectedPersonaProvider.notifier).clear();
    }

    final List<String> savedPaths = [];
    if (attachments != null && attachments.isNotEmpty) {
      final appDir = await ref.read(storageDirectoryProvider.future);
      final attachmentsDir = Directory('${appDir.path}/attachments');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      for (final file in attachments) {
        final fileName = file.path.split('/').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = '${attachmentsDir.path}/${timestamp}_$fileName';
        await file.copy(newPath);
        savedPaths.add(newPath);
      }
    }

    final userMessage = Message(
      id: generateUuid(),
      conversationId: _currentConversationId!,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
      status: MessageStatus.complete,
      attachmentPaths: savedPaths.isNotEmpty ? savedPaths : null,
    );

    final assistantMessageId = generateUuid();
    var assistantMessage = Message(
      id: assistantMessageId,
      conversationId: _currentConversationId!,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      status: MessageStatus.streaming,
      modelId: selectedModel?.id,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      isStreaming: true,
      streamingMessage: assistantMessage,
      clearError: true,
    );
    ref.read(isStreamingProvider.notifier).setStreaming(true);

    await _saveMessage(userMessage);
    await _saveMessage(assistantMessage);

    // Start background service to prevent suspension
    ref.read(chatBackgroundServiceProvider).start();

    _resetCheckpointMetrics();
    _updateSavedMetrics(assistantMessage);

    final messagesForApi = _buildMessagesForApi(selectedModel);

    try {
      _streamSubscription?.cancel();
      _uiUpdateTimer?.cancel();

      String reasoningContent = '';
      var streamingAssistantMessage = assistantMessage;
      _latestStreamingMessage = streamingAssistantMessage;

      if (chatService != null) {
        final mcpConfig = ref.read(chatMcpConfigProvider);
        final integrations =
            mcpConfig.enabled && mcpConfig.integrations.isNotEmpty
            ? mcpConfig.integrations
            : null;

        final registry = ref.read(toolRegistryProvider);
        final tools = mcpConfig.enabled
            ? await registry.listTools()
            : const <ToolDefinition>[];

        final collectedToolCalls = <ToolCallData>[];

        bool stateNeedsUpdate = false;

        void updateUiState() {
          if (!stateNeedsUpdate) return;
          stateNeedsUpdate = false;

          final streamConvId = assistantMessage.conversationId;
          final isCurrentContext = _currentConversationId == streamConvId;

          if (isCurrentContext) {
            state = state.copyWith(streamingMessage: streamingAssistantMessage);
          }
        }

        _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
          updateUiState();
        });

        _streamSubscription = chatService
            .sendMessage(
              server: server,
              modelId: selectedModel?.id ?? 'default',
              messages: messagesForApi,
              params: chatParams,
              integrations: integrations,
              tools: tools,
            )
            .listen(
              (response) async {
                final streamConvId = assistantMessage.conversationId;
                final isCurrentContext = _currentConversationId == streamConvId;

                switch (response.type) {
                  case ChatResponseType.message:
                    streamingAssistantMessage = streamingAssistantMessage
                        .copyWith(
                          content:
                              streamingAssistantMessage.content +
                              (response.content ?? ''),
                          isProcessing: false,
                        );
                    _latestStreamingMessage = streamingAssistantMessage;

                    _chunkCount++;

                    if (_shouldCheckpointSave(streamingAssistantMessage)) {
                      // Non-blocking enqueue — never stalls the stream listener.
                      _saveService?.enqueue(streamingAssistantMessage);
                      _updateSavedMetrics(streamingAssistantMessage);
                      _resetCheckpointMetrics();
                    }

                    stateNeedsUpdate = true;
                    break;
                  case ChatResponseType.reasoning:
                    reasoningContent += response.reasoningContent ?? '';
                    streamingAssistantMessage = streamingAssistantMessage
                        .copyWith(
                          reasoningContent: reasoningContent,
                          isProcessing: false,
                        );
                    _latestStreamingMessage = streamingAssistantMessage;

                    _chunkCount++;

                    if (_shouldCheckpointSave(streamingAssistantMessage)) {
                      // Non-blocking enqueue — never stalls the stream listener.
                      _saveService?.enqueue(streamingAssistantMessage);
                      _updateSavedMetrics(streamingAssistantMessage);
                      _resetCheckpointMetrics();
                    }

                    stateNeedsUpdate = true;
                    break;
                  case ChatResponseType.processing:
                    // Model is working but hasn't output content yet
                    streamingAssistantMessage = streamingAssistantMessage
                        .copyWith(isProcessing: true);
                    _latestStreamingMessage = streamingAssistantMessage;
                    stateNeedsUpdate = true;
                    break;
                  case ChatResponseType.timeoutError:
                  case ChatResponseType.error:
                    _uiUpdateTimer?.cancel();
                    _uiUpdateTimer = null;
                    // Error reached without receiving content or mid-stream
                    streamingAssistantMessage = streamingAssistantMessage.copyWith(
                      status: MessageStatus.error,
                      errorMessage:
                          response.content ??
                          (response.type == ChatResponseType.timeoutError
                              ? 'Model is taking too long to respond. This may happen with free tier models.'
                              : 'An unknown error occurred.'),
                      isProcessing: false,
                    );
                    _latestStreamingMessage = streamingAssistantMessage;

                    if (isCurrentContext) {
                      _replaceMessageInState(
                        streamingAssistantMessage,
                        clearStreaming: true,
                      );
                      state = state.copyWith(
                        isStreaming: false,
                        errorMessage: streamingAssistantMessage.errorMessage,
                      );
                    }
                    ref.read(isStreamingProvider.notifier).setStreaming(false);
                    _latestStreamingMessage = null;
                    // Save error message to storage
                    await _saveService?.flush();
                    await _saveMessage(streamingAssistantMessage);
                    break;
                  case ChatResponseType.toolCall:
                    if (response.toolCall != null) {
                      collectedToolCalls.add(response.toolCall!);
                    }
                    break;
                  case ChatResponseType.invalidToolCall:
                  case ChatResponseType.done:
                    break;
                }
              },
              onDone: () async {
                _uiUpdateTimer?.cancel();
                _uiUpdateTimer = null;
                updateUiState();

                // Flush batched checkpoint saves before finalising UI state.
                await _saveService?.flush();
                ref.read(chatBackgroundServiceProvider).stop();
                final streamConvId = assistantMessage.conversationId;
                final isCurrentContext = _currentConversationId == streamConvId;
                final streamingMessage = streamingAssistantMessage;
                // ignore: unnecessary_null_comparison
                if (streamingMessage != null) {
                  // Check if content is empty - this happens when free models refuse or fail
                  final hasContent =
                      streamingMessage.content.isNotEmpty ||
                      (streamingMessage.reasoningContent?.isNotEmpty ?? false);

                  if (!hasContent) {
                    // Mark as error if no content received
                    final errorMessage = streamingMessage.copyWith(
                      status: MessageStatus.error,
                      errorMessage:
                          'Model failed to respond. This may happen with free tier models that refuse certain prompts or when the service is busy.',
                      isProcessing: false,
                    );
                    await _saveMessage(errorMessage);
                    if (isCurrentContext) {
                      _replaceMessageInState(
                        errorMessage,
                        clearStreaming: true,
                      );
                      state = state.copyWith(
                        isStreaming: false,
                        errorMessage: errorMessage.errorMessage,
                      );
                    }
                    ref.read(isStreamingProvider.notifier).setStreaming(false);
                    _latestStreamingMessage = null;
                  } else {
                    // Normal completion with content
                    var finalMessage = streamingMessage.copyWith(
                      status: MessageStatus.complete,
                      isProcessing: false,
                    );

                    // ---- TOOL LOOP INTEGRATION ----
                    if (mcpConfig.enabled && collectedToolCalls.isNotEmpty) {
                      try {
                        final registry = ref.read(toolRegistryProvider);
                        final adapter = createAdapterForServerType(server.type);

                        final preParsedCalls = collectedToolCalls
                            .map(
                              (tc) => ParsedToolCall(
                                id: tc.tool,
                                name: tc.tool,
                                arguments: tc.arguments,
                              ),
                            )
                            .toList();

                        final loop = ToolExecutionLoop(
                          adapter: adapter,
                          registry: registry,
                          onRequestApproval: (call) async {
                            final completer = Completer<bool>();
                            state = state.copyWith(
                              pendingToolApproval: PendingToolApproval(
                                toolCall: call,
                                completer: completer,
                              ),
                            );

                            final result = await completer.future;

                            state = state.copyWith(
                              clearPendingApproval: true,
                            );

                            return result;
                          },
                        );

                        final loopResult = await loop.run(
                          initialUserMessage: content,
                          assistantContent: streamingAssistantMessage.content,
                          preParsedCalls: preParsedCalls,
                        );

                        if (loopResult.events.isNotEmpty) {
                          finalMessage = finalMessage.copyWith(
                            toolSessionId: loop.sessionId,
                            toolEvents: loopResult.events,
                          );
                        }
                      } catch (e) {
                        Log.error('Tool execution loop failed: $e');
                      }
                    }
                    // ---- END TOOL LOOP INTEGRATION ----

                    await _saveMessage(finalMessage);
                    if (isCurrentContext) {
                      _replaceMessageInState(
                        finalMessage,
                        clearStreaming: true,
                      );
                      state = state.copyWith(isStreaming: false);
                    }
                    ref.read(isStreamingProvider.notifier).setStreaming(false);
                    _latestStreamingMessage = null;
                    if (_currentConversationId != null) {
                      final preview = finalMessage.content.length > 100
                          ? '${finalMessage.content.substring(0, 100)}...'
                          : finalMessage.content;
                      await ref
                          .read(conv.conversationsProvider.notifier)
                          .updatePreview(
                            _currentConversationId!,
                            preview,
                            DateTime.now(),
                          );

                      final userMessage = state.messages
                          .where((m) => m.role == MessageRole.user)
                          .firstOrNull;
                      if (userMessage != null &&
                          userMessage.content.length > 10) {
                        _autoGenerateTitle(
                          userMessage.content,
                          finalMessage.content,
                        );
                      }
                    }

                    _chunkCount = 0;
                    _lastCheckpointTime = null;
                    _lastSavedContentLength = 0;
                    _lastSavedReasoningLength = 0;
                  }
                }
              },
              onError: (error) async {
                _uiUpdateTimer?.cancel();
                _uiUpdateTimer = null;
                _chunkCount = 0;
                _lastCheckpointTime = null;
                _lastSavedContentLength = 0;
                _lastSavedReasoningLength = 0;
                // Flush any batched saves before processing the error state.
                await _saveService?.flush();
                final errorMessage =
                    (_latestStreamingMessage ?? state.streamingMessage)
                        ?.copyWith(
                          status: MessageStatus.error,
                          errorMessage: error.toString(),
                        );
                if (errorMessage != null) {
                  await _saveMessage(errorMessage);

                  ref.read(chatBackgroundServiceProvider).stop();

                  final streamConvId = assistantMessage.conversationId;
                  if (_currentConversationId == streamConvId) {
                    _replaceMessageInState(errorMessage, clearStreaming: true);
                    state = state.copyWith(
                      isStreaming: false,
                      errorMessage: error.toString(),
                    );
                  }
                }
                ref.read(isStreamingProvider.notifier).setStreaming(false);
                _latestStreamingMessage = null;
              },
            );
      }
    } catch (e) {
      _uiUpdateTimer?.cancel();
      _uiUpdateTimer = null;
      final errorMsg = assistantMessage.copyWith(
        status: MessageStatus.error,
        errorMessage: e.toString(),
        isProcessing: false,
      );
      await _saveMessage(errorMsg);

      state = state.copyWith(
        isStreaming: false,
        errorMessage: e.toString(),
        clearStreaming: true,
      );
      ref.read(isStreamingProvider.notifier).setStreaming(false);
      _latestStreamingMessage = null;
      ref.read(chatBackgroundServiceProvider).stop();
    }
  }

  List<Message> _buildMessagesForApi(ModelInfo? selectedModel) {
    final settings = ref.read(settingsProvider);
    final messages = <Message>[];

    final personaPrompt = _getPersonaSystemPrompt();
    if (personaPrompt != null) {
      messages.add(
        Message(
          id: 'system-$_currentConversationId',
          conversationId: _currentConversationId ?? '',
          role: MessageRole.system,
          content: personaPrompt,
          createdAt: DateTime.now(),
          status: MessageStatus.complete,
        ),
      );
    } else if (settings.showSystemMessages) {
      messages.add(
        Message(
          id: 'system-default-$_currentConversationId',
          conversationId: _currentConversationId ?? '',
          role: MessageRole.system,
          content:
              'You are LocalMind, a helpful AI assistant. Provide clear, accurate, and concise responses.',
          createdAt: DateTime.now(),
          status: MessageStatus.complete,
        ),
      );
    }

    for (final message in state.messages) {
      if (message.role != MessageRole.system || settings.showSystemMessages) {
        messages.add(message);
      }
    }

    final contextLength = ref.read(chatParamsProvider).contextLength;
    return _truncateToContextWindow(messages, contextLength);
  }

  String? _getPersonaSystemPrompt() {
    final conversation = ref.read(conv.activeConversationProvider);
    final personaId = conversation?.personaId;
    if (personaId == null) return null;

    if (conversation?.systemPrompt != null &&
        conversation!.systemPrompt!.isNotEmpty) {
      return conversation.systemPrompt;
    }

    try {
      final personasAsync = ref.read(personasNotifierProvider);
      final personas = personasAsync.value ?? [];
      final persona = personas.firstWhere(
        (p) => p.id == personaId,
        orElse: () => throw Exception('Persona not found'),
      );
      if (persona.systemPrompt.isNotEmpty) {
        return persona.systemPrompt;
      }
    } catch (_) {}

    return null;
  }

  List<Message> _truncateToContextWindow(
    List<Message> messages,
    int contextLength,
  ) {
    if (messages.isEmpty) return messages;

    int estimatedTokens = 0;
    final result = <Message>[];
    const tokensPerChar = 4;

    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      estimatedTokens += (message.content.length / tokensPerChar).ceil();

      if (estimatedTokens > contextLength) {
        break;
      }
      result.insert(0, message);
    }

    return result;
  }

  void _autoGenerateTitle(String userContent, String assistantContent) {
    final settings = ref.read(settingsProvider);
    if (!settings.autoGenerateTitle) return;
    if (_currentConversationId == null) return;

    final activeConv = ref.read(conv.activeConversationProvider);
    if (activeConv == null) return;
    if (activeConv.title != 'New Chat') return;

    final title = userContent.length > 40
        ? '${userContent.substring(0, 40)}...'
        : userContent;

    ref
        .read(conv.conversationsProvider.notifier)
        .renameConversation(_currentConversationId!, title);
  }

  Future<void> cancelStream() async {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;
    _clearPendingApproval();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    ref.read(chatServiceProvider)?.cancelStream();
    ref.read(chatBackgroundServiceProvider).stop();

    _chunkCount = 0;
    _lastCheckpointTime = null;
    _lastSavedContentLength = 0;
    _lastSavedReasoningLength = 0;

    // Flush any in-flight checkpoint saves before writing the final state.
    await _saveService?.flush();

    final streamingMessage = _latestStreamingMessage ?? state.streamingMessage;
    if (streamingMessage != null) {
      final finalMessage = streamingMessage.copyWith(
        status: MessageStatus.complete,
        isProcessing: false,
      );
      await _saveMessage(finalMessage);
      _replaceMessageInState(finalMessage, clearStreaming: true);
    }

    state = state.copyWith(isStreaming: false, clearStreaming: true);
    ref.read(isStreamingProvider.notifier).setStreaming(false);
    _latestStreamingMessage = null;
  }

  Future<void> retryLastMessage() async {
    final messages = state.messages;
    if (messages.isEmpty) return;

    if (messages.last.role == MessageRole.assistant) {
      final lastAssistantIndex = messages.lastIndexWhere(
        (m) => m.role == MessageRole.assistant,
      );
      if (lastAssistantIndex > 0) {
        final userMessage = messages[lastAssistantIndex - 1];
        final messagesToRemove = messages.sublist(lastAssistantIndex);
        final db = ref.read(databaseProvider);

        for (final msg in messagesToRemove) {
          final query = db.messageBox
              .query(MessageEntity_.id.equals(msg.id))
              .build();
          db.messageBox.removeMany(query.findIds());
          query.close();
        }

        state = state.copyWith(
          messages: messages.sublist(0, lastAssistantIndex),
          clearStreaming: true,
        );

        await sendMessage(
          userMessage.content,
          attachments: userMessage.attachmentPaths
              ?.map((p) => File(p))
              .toList(),
        );
      }
    }
  }

  Future<void> retryMessage(String messageId) async {
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final message = state.messages[messageIndex];
    if (message.role != MessageRole.assistant) return;

    // Find the preceding user message
    if (messageIndex > 0 &&
        state.messages[messageIndex - 1].role == MessageRole.user) {
      final userMessage = state.messages[messageIndex - 1];

      // Remove this assistant message and all subsequent messages
      final messagesToRemove = state.messages.sublist(messageIndex);
      final db = ref.read(databaseProvider);

      for (final msg in messagesToRemove) {
        final query = db.messageBox
            .query(MessageEntity_.id.equals(msg.id))
            .build();
        db.messageBox.removeMany(query.findIds());
        query.close();
      }

      state = state.copyWith(
        messages: state.messages.sublist(0, messageIndex),
        clearStreaming: true,
      );

      await sendMessage(
        userMessage.content,
        attachments: userMessage.attachmentPaths?.map((p) => File(p)).toList(),
      );
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final db = ref.read(databaseProvider);
    final query = db.messageBox
        .query(MessageEntity_.id.equals(messageId))
        .build();
    db.messageBox.removeMany(query.findIds());
    query.close();

    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;

    final message = state.messages[messageIndex];
    if (message.role != MessageRole.user) return;
    if (newContent.trim().isEmpty) return;
    if (newContent == message.content) return;

    final attachmentPaths = message.attachmentPaths;

    final messagesToRemove = state.messages.sublist(messageIndex);
    final db = ref.read(databaseProvider);
    for (final msg in messagesToRemove) {
      final query = db.messageBox
          .query(MessageEntity_.id.equals(msg.id))
          .build();
      db.messageBox.removeMany(query.findIds());
      query.close();
    }

    state = state.copyWith(
      messages: state.messages.sublist(0, messageIndex),
      clearStreaming: true,
    );

    await sendMessage(
      newContent,
      attachments: attachmentPaths?.map((p) => File(p)).toList(),
    );
  }

  Future<void> _saveMessage(Message message) async {
    final db = ref.read(databaseProvider);
    await db.store.runInTransactionAsync(
      TxMode.write,
      _saveMessageInBackground,
      message,
    );
  }

  static void _saveMessageInBackground(Store store, Message message) {
    final box = store.box<MessageEntity>();
    final convBox = store.box<ConversationEntity>();

    final query = box.query(MessageEntity_.id.equals(message.id)).build();
    final existing = query.findFirst();
    query.close();

    final entity = MessageEntity.fromDomain(message);
    if (existing != null) {
      entity.internalId = existing.internalId;
    }

    final convQuery = convBox
        .query(ConversationEntity_.id.equals(message.conversationId))
        .build();
    final convEntity = convQuery.findFirst();
    convQuery.close();

    if (convEntity != null) {
      entity.conversation.target = convEntity;
      entity.conversationUid = convEntity.id;
    } else {
      entity.conversationUid = message.conversationId;
    }

    box.put(entity);
  }

  Future<void> clearConversation() async {
    final db = ref.read(databaseProvider);
    if (_currentConversationId != null) {
      final query = db.messageBox
          .query(MessageEntity_.conversationUid.equals(_currentConversationId!))
          .build();
      db.messageBox.removeMany(query.findIds());
      query.close();
    }
    _currentConversationId = null;
    state = const ChatState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
