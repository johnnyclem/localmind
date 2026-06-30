import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/core/models/enums.dart';
import 'package:localmind/features/servers/data/models/server.dart';
import 'package:localmind/features/servers/data/repositories/server_api_service.dart';

class TestInterceptor extends Interceptor {
  final dynamic responseData;
  TestInterceptor(this.responseData);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(Response(
      requestOptions: options,
      data: responseData,
      statusCode: 200,
    ));
  }
}

class RequestRecordingInterceptor extends Interceptor {
  final List<RequestOptions> requests = [];
  final int statusCode;
  RequestRecordingInterceptor({this.statusCode = 200});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: statusCode,
        data: {'status': 'ok'},
      ),
    );
  }
}

class FailingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'connection refused',
      ),
    );
  }
}

void main() {
  group('ServerApiService - OpenAI/llama.cpp model list parsing', () {
    late Server testServer;

    setUp(() {
      testServer = Server(
        id: 'test-openai',
        name: 'Test OpenAI Compatible',
        type: ServerType.openAICompatible,
        host: 'localhost',
        port: 8080,
        createdAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );
    });

    test('parses models successfully using fallback data array (llama.cpp / OpenAI standard)', () async {
      final mockData = {
        "object": "list",
        "data": [
          {
            "id": "meta-llama/Llama-3-8B-Instruct",
            "object": "model",
            "created": 1677610602,
            "owned_by": "openai",
            "meta": {
              "n_ctx_train": 8192,
              "n_params": 8000000000,
              "size": 4800000000
            }
          }
        ]
      };

      final dio = Dio()..interceptors.add(TestInterceptor(mockData));
      final service = ServerApiService(dio);

      final models = await service.fetchModels(testServer);

      expect(models, hasLength(1));
      final model = models.first;
      expect(model.id, "meta-llama/Llama-3-8B-Instruct");
      expect(model.name, "Meta Llama/Llama 3 8B Instruct");
      expect(model.contextLength, 8192);
      expect(model.parameterCount, 8.0); // 8000000000 / 1000000000
      expect(model.fileSize, 4800000000);
      expect(model.serverType, ServerType.openAICompatible);
      expect(model.serverId, testServer.id);
    });

    test('parses models successfully using custom models array (LM Studio)', () async {
      final mockData = {
        "models": [
          {
            "key": "lmstudio-community/Meta-Llama-3-8B-Instruct-GGUF",
            "display_name": "Llama 3 8B Instruct",
            "description": "LM Studio test model",
            "params_string": "8B",
            "max_context_length": 4096,
            "size_bytes": 5000000000,
            "quantization": {
              "name": "Q4_K_M"
            },
            "architecture": "llama"
          }
        ]
      };

      final dio = Dio()..interceptors.add(TestInterceptor(mockData));
      final service = ServerApiService(dio);

      final models = await service.fetchModels(testServer);

      expect(models, hasLength(1));
      final model = models.first;
      expect(model.id, "lmstudio-community/Meta-Llama-3-8B-Instruct-GGUF");
      expect(model.name, "Llama 3 8B Instruct");
      expect(model.description, "LM Studio test model");
      expect(model.parameterCount, 8.0);
      expect(model.contextLength, 4096);
      expect(model.fileSize, 5000000000);
      expect(model.quantization, "Q4_K_M");
      expect(model.architecture, "llama");
    });

    test('handles running models with fallback data array (llama.cpp)', () async {
      final mockData = {
        "object": "list",
        "data": [
          {
            "id": "active-model",
            "object": "model"
          }
        ]
      };

      final dio = Dio()..interceptors.add(TestInterceptor(mockData));
      final service = ServerApiService(dio);

      final lmStudioServer = testServer.copyWith(type: ServerType.lmStudio);
      final running = await service.fetchRunningModels(lmStudioServer);

      expect(running, contains("active-model"));
    });

    test('handles running models with custom models array and loaded instances (LM Studio)', () async {
      final mockData = {
        "models": [
          {
            "key": "active-model-lm",
            "loaded_instances": [
              {"id": "inst_1"}
            ]
          },
          {
            "key": "inactive-model-lm",
            "loaded_instances": []
          }
        ]
      };

      final dio = Dio()..interceptors.add(TestInterceptor(mockData));
      final service = ServerApiService(dio);

      final lmStudioServer = testServer.copyWith(type: ServerType.lmStudio);
      final running = await service.fetchRunningModels(lmStudioServer);

      expect(running, contains("active-model-lm"));
      expect(running, isNot(contains("inactive-model-lm")));
    });

    test('handles custom string quantization value gracefully', () async {
      final mockData = {
        "data": [
          {
            "id": "model-with-string-quant",
            "quantization": "Q5_K_M"
          }
        ]
      };

      final dio = Dio()..interceptors.add(TestInterceptor(mockData));
      final service = ServerApiService(dio);

      final models = await service.fetchModels(testServer);
      expect(models.first.quantization, "Q5_K_M");
    });

    test('handles actual user llama.cpp endpoint output successfully with Map architecture', () async {
      final mockData = {
        "data": [
          {
            "id": "Gemma-4-31B:IQ4_XS",
            "aliases": [],
            "tags": [],
            "object": "model",
            "owned_by": "llamacpp",
            "created": 1779851034,
            "status": {
              "value": "unloaded",
              "args": [
                "D:\\llamacpp\\llama-server.exe",
                "--host",
                "127.0.0.1",
                "--jinja",
                "--mlock",
                "--no-mmap",
                "--port",
                "0",
                "--alias",
                "Gemma-4-31B:IQ4_XS",
                "--ctx-size",
                "65536",
                "--cache-type-k",
                "q4_0",
                "--cache-type-v",
                "q4_0",
                "--flash-attn",
                "true",
                "--model",
                "./models/gemma-4-31B-it-llmfan-i1-IQ4_XS.gguf",
                "--parallel",
                "1",
                "--reasoning",
                "off"
              ],
              "preset": "[Gemma-4-31B:IQ4_XS]\njinja = true\nmlock = 1\nmmap = 0\nctx-size = 65536\ncache-type-k = q4_0\ncache-type-v = q4_0\nflash-attn = true\nmodel = ./models/gemma-4-31B-it-llmfan-i1-IQ4_XS.gguf\nparallel = 1\nreasoning = off\n\n"
            },
            "architecture": {
              "input_modalities": ["text"],
              "output_modalities": ["text"]
            }
          }
        ],
        "object": "list"
      };

      final dio = Dio()..interceptors.add(TestInterceptor(mockData));
      final service = ServerApiService(dio);

      final models = await service.fetchModels(testServer);
      expect(models, hasLength(1));
      expect(models.first.id, "Gemma-4-31B:IQ4_XS");
      expect(models.first.architecture, isNull);
    });
  });

  group('ServerApiService - Ollama load behavior', () {
    test('loadModel is a no-op for Ollama (does not POST /api/generate)', () async {
      final ollamaServer = Server(
        id: 'test-ollama',
        name: 'Test Ollama',
        type: ServerType.ollama,
        host: 'localhost',
        port: 11434,
        createdAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );

      final dio = Dio()..interceptors.add(RequestRecordingInterceptor());
      final service = ServerApiService(dio);

      await service.loadModel(ollamaServer, 'llama3.2:latest');
      await service.loadModelWithInstanceId(ollamaServer, 'llama3.2:latest');

      final recorder =
          dio.interceptors.firstWhere((i) => i is RequestRecordingInterceptor)
              as RequestRecordingInterceptor;
      expect(recorder.requests, isEmpty,
          reason: 'Ollama should not issue an explicit load request; '
              'calling /api/generate without a prompt can trigger an '
              'auto-pull of the model from the Ollama registry.');
    });

    test('unloadModel for Ollama posts keep_alive=0 and a valid payload', () async {
      final ollamaServer = Server(
        id: 'test-ollama',
        name: 'Test Ollama',
        type: ServerType.ollama,
        host: 'localhost',
        port: 11434,
        createdAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );

      final dio = Dio()..interceptors.add(RequestRecordingInterceptor());
      final service = ServerApiService(dio);

      await service.unloadModel(ollamaServer, 'llama3.2:latest');

      final recorder =
          dio.interceptors.firstWhere((i) => i is RequestRecordingInterceptor)
              as RequestRecordingInterceptor;
      expect(recorder.requests, hasLength(1));
      expect(recorder.requests.first.path, endsWith('/api/generate'));
      expect(recorder.requests.first.data, containsPair('keep_alive', 0));
      expect(recorder.requests.first.data, containsPair('model', 'llama3.2:latest'));
      expect(recorder.requests.first.data, containsPair('prompt', ''));
    });

    test('unloadModel for Ollama surfaces failures', () async {
      final ollamaServer = Server(
        id: 'test-ollama',
        name: 'Test Ollama',
        type: ServerType.ollama,
        host: 'localhost',
        port: 11434,
        createdAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );

      final dio = Dio()..interceptors.add(FailingInterceptor());
      final service = ServerApiService(dio);

      expect(
        () => service.unloadModel(ollamaServer, 'llama3.2:latest'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
