import 'package:dio/dio.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/enums.dart';
import '../../models/data/models/model_info.dart';
import 'models/server.dart';

class ServerApiService {
  final Dio _dio;

  ServerApiService(this._dio);

  Future<bool> testConnection(Server server) async {
    try {
      final response = await _dio.get(
        server.modelsEndpoint,
        options: Options(
          headers: _getAuthHeaders(server),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<int?> pingServer(Server server) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _dio.head(
        server.baseUrl,
        options: Options(headers: _getAuthHeaders(server)),
      );
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      return null;
    }
  }

  Future<List<ModelInfo>> fetchModels(Server server) async {
    try {
      final response = await _dio.get(
        server.modelsEndpoint,
        options: Options(headers: _getAuthHeaders(server)),
      );

      switch (server.type) {
        case ServerType.lmStudio:
        case ServerType.openAICompatible:
          return _parseOpenAICompatibleModels(response.data, server);
        case ServerType.ollama:
          return _parseOllamaModels(response.data, server);
        case ServerType.openRouter:
          return _parseOpenRouterModels(response.data, server);
        case ServerType.onDevice:
          return [];
      }
    } catch (e) {
      throw Exception('Failed to fetch models: $e');
    }
  }

  Future<Set<String>> fetchRunningModels(Server server) async {
    if (server.type == ServerType.openRouter ||
        server.type == ServerType.openAICompatible) {
      return {};
    }

    try {
      final response = await _dio.get(
        server.runningModelsEndpoint,
        options: Options(headers: _getAuthHeaders(server)),
      );

      switch (server.type) {
        case ServerType.lmStudio:
        case ServerType.openAICompatible:
          return _parseRunningOpenAICompatibleModels(response.data);
        case ServerType.ollama:
          return _parseRunningOllamaModels(response.data);
        case ServerType.openRouter:
          return {};
        case ServerType.onDevice:
          return {};
      }
    } catch (e) {
      return {};
    }
  }

  Future<void> loadModel(Server server, String modelId) async {
    if (server.type == ServerType.openRouter ||
        server.type == ServerType.onDevice) {
      return;
    }

    switch (server.type) {
      case ServerType.lmStudio:
      case ServerType.openAICompatible:
        try {
          await _dio.post(
            server.loadModelEndpoint,
            data: {'model': modelId},
            options: Options(headers: _getAuthHeaders(server)),
          );
        } catch (_) {
          // Not all OpenAI-compatible servers support this endpoint
        }
        break;
      case ServerType.ollama:
        // Ollama auto-loads models on /api/chat. Calling /api/generate here
        // would trigger an auto-pull (download) when the model is not already
        // present on the Ollama server, which is not what the user wants.
        return;
      case ServerType.openRouter:
      case ServerType.onDevice:
        break;
    }
  }

  Future<String?> loadModelWithInstanceId(Server server, String modelId) async {
    if (server.type == ServerType.openRouter ||
        server.type == ServerType.onDevice) {
      return null;
    }

    switch (server.type) {
      case ServerType.lmStudio:
      case ServerType.openAICompatible:
        try {
          final response = await _dio.post(
            server.loadModelEndpoint,
            data: {'model': modelId, 'echo_load_config': true},
            options: Options(headers: _getAuthHeaders(server)),
          );
          return response.data['instance_id'] as String?;
        } catch (_) {
          return null;
        }
      case ServerType.ollama:
        // See note in loadModel: Ollama auto-loads on /api/chat, so we do not
        // issue an explicit /api/generate load (which would auto-pull the
        // model if missing on the remote).
        return null;
      case ServerType.openRouter:
      case ServerType.onDevice:
        return null;
    }
  }

  Future<void> unloadModel(
    Server server,
    String modelId, {
    String? instanceId,
  }) async {
    if (server.type == ServerType.openRouter ||
        server.type == ServerType.onDevice) {
      return;
    }

    switch (server.type) {
      case ServerType.lmStudio:
      case ServerType.openAICompatible:
        try {
          await _dio.post(
            server.unloadModelEndpoint,
            data: {'instance_id': instanceId ?? modelId},
            options: Options(headers: _getAuthHeaders(server)),
          );
        } catch (_) {
          // Not all OpenAI-compatible servers support this endpoint
        }
        break;
      case ServerType.ollama:
        await _dio.post(
          server.unloadModelEndpoint,
          data: {
            'model': modelId,
            'keep_alive': 0,
            'prompt': '',
          },
          options: Options(headers: _getAuthHeaders(server)),
        );
        break;
      case ServerType.openRouter:
      case ServerType.onDevice:
        break;
    }
  }

  Set<String> _parseRunningOpenAICompatibleModels(dynamic data) {
    final runningModels = <String>{};
    final modelItems = data['models'] ?? data['data'];
    if (modelItems != null && modelItems is List) {
      for (final item in modelItems) {
        if (item is! Map) continue;
        final id = item['key']?.toString() ??
            item['name']?.toString() ??
            item['id']?.toString() ??
            '';
        if (id.isEmpty) continue;

        final loadedInstances = item['loaded_instances'];
        if (loadedInstances is List) {
          if (loadedInstances.isNotEmpty) {
            runningModels.add(id);
          }
        } else {
          // Servers without loaded_instances (e.g. llama.cpp) always have
          // their model running if it appears in the model list
          runningModels.add(id);
        }
      }
    }
    return runningModels;
  }

  Set<String> _parseRunningOllamaModels(dynamic data) {
    final runningModels = <String>{};
    if (data['models'] != null) {
      for (final item in data['models']) {
        runningModels.add(item['name'] as String? ?? '');
      }
    }
    return runningModels;
  }

  Map<String, String>? _getAuthHeaders(Server server) {
    if (server.apiKey != null && server.apiKey!.isNotEmpty) {
      return {'Authorization': 'Bearer ${server.apiKey}'};
    }
    return null;
  }

  List<ModelInfo> _parseOpenAICompatibleModels(dynamic data, Server server) {
    final List<ModelInfo> models = [];

    // Build a lookup from the OpenAI-style 'data' array for metadata
    // that may be missing from the 'models' array (e.g. llama.cpp)
    final Map<String, Map<String, dynamic>> metaById = {};
    if (data['data'] != null && data['data'] is List) {
      for (final item in data['data']) {
        if (item is Map) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            metaById[id] = (item['meta'] as Map<String, dynamic>?) ?? {};
          }
        }
      }
    }

    final modelItems = data['models'] ?? data['data'];
    if (modelItems != null && modelItems is List) {
      for (final item in modelItems) {
        if (item is! Map) continue;
        final id = item['key']?.toString() ??
            item['name']?.toString() ??
            item['id']?.toString() ??
            '';
        if (id.isEmpty) continue;

        final displayName = item['display_name']?.toString();
        final quantization = item['quantization'];
        final paramsString = item['params_string']?.toString();
        
        final meta = metaById[id] ?? (item['meta'] as Map<String, dynamic>?);
        if (meta == null && metaById.isNotEmpty && data['models'] != null) {
          Log.warning('Metadata join failed for model: $id');
        }
        final finalMeta = meta ?? {};

        String? quantName;
        if (quantization is Map) {
          quantName = quantization['name']?.toString();
        } else if (quantization is String) {
          quantName = quantization;
        }

        final archValue = item['architecture'];
        String? archName;
        if (archValue is String) {
          archName = archValue;
        }

        models.add(
          ModelInfo(
            id: id,
            name: displayName ?? _formatModelName(id),
            description: item['description']?.toString(),
            parameterCount: _parseParameterString(paramsString) ??
                _paramCountFromMeta(finalMeta['n_params']),
            contextLength: _toInt(item['max_context_length']) ??
                _toInt(finalMeta['n_ctx_train']),
            fileSize: _toInt(item['size_bytes']) ??
                _toInt(finalMeta['size']),
            quantization: quantName,
            architecture: archName,
            serverType: server.type,
            serverId: server.id,
          ),
        );
      }
    }
    return models;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _paramCountFromMeta(dynamic nParams) {
    if (nParams == null) return null;
    if (nParams is int) return nParams / 1000000000;
    if (nParams is double) return nParams / 1000000000;
    if (nParams is String) {
      final parsedDouble = double.tryParse(nParams);
      if (parsedDouble != null) return parsedDouble / 1000000000;
    }
    return null;
  }

  List<ModelInfo> _parseOllamaModels(dynamic data, Server server) {
    final List<ModelInfo> models = [];
    if (data['models'] != null) {
      for (final item in data['models']) {
        final details = item['details'] ?? {};
        final paramSize = details['parameter_size'] as String? ?? '';
        models.add(
          ModelInfo(
            id: item['name'] ?? '',
            name: _formatModelName(item['name'] ?? ''),
            fileSize: item['size'] as int?,
            parameterCount: _parseParameterSize(paramSize),
            quantization: details['quantization_level'] as String?,
            architecture: details['family'] as String?,
            serverType: server.type,
            serverId: server.id,
            modifiedAt: item['modified_at'] != null
                ? DateTime.tryParse(item['modified_at'])
                : null,
          ),
        );
      }
    }
    return models;
  }

  List<ModelInfo> _parseOpenRouterModels(dynamic data, Server server) {
    final List<ModelInfo> models = [];
    if (data['data'] != null) {
      for (final item in data['data']) {
        final modality = item['architecture']?['modality'] as String?;
        final isTextModel = modality == null ||
            modality.isEmpty ||
            !modality.contains('->') ||
            modality.split('->').last.contains('text');
        if (isTextModel) {
          models.add(
            ModelInfo(
              id: item['id'] ?? '',
              name: item['name'] ?? '',
              description: item['description'] as String?,
              contextLength: item['context_length'] as int?,
              architecture: item['architecture']?['tokenizer'] as String?,
              serverType: server.type,
              serverId: server.id,
            ),
          );
        }
      }
    }
    return models;
  }

  String _formatModelName(String id) {
    return id
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  double? _parseParameterSize(String size) {
    final cleaned = size.replaceAll('B', '').replaceAll('b', '').trim();
    return double.tryParse(cleaned);
  }

  double? _parseParameterString(String? paramsString) {
    if (paramsString == null) return null;
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*[Bb]');
    final match = regex.firstMatch(paramsString);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}
