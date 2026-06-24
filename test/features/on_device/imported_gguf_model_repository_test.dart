import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/features/on_device/data/imported_gguf_model_repository.dart';
import 'package:localmind/features/on_device/data/models/on_device_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const storageKey = 'imported_gguf_models_v1';

  Future<ImportedGgufModelRepository> createRepository({
    Map<String, Object> initialValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    return ImportedGgufModelRepository(prefs);
  }

  group('ImportedGgufModelMetadata', () {
    test('serializes and converts to a llama.cpp on-device model', () {
      final importedAt = DateTime.utc(2026, 6, 21, 12);
      final metadata = ImportedGgufModelMetadata(
        id: 'gguf-test',
        name: 'Tiny Llama',
        filePath: '/tmp/Tiny-Llama.Q4.gguf',
        fileSizeBytes: 1234,
        importedAt: importedAt,
      );

      final restored = ImportedGgufModelMetadata.fromJson(
        json.decode(json.encode(metadata.toJson())) as Map<String, dynamic>,
      );
      final model = restored.toOnDeviceModel();

      expect(restored.id, metadata.id);
      expect(restored.name, metadata.name);
      expect(restored.filePath, metadata.filePath);
      expect(restored.fileSizeBytes, metadata.fileSizeBytes);
      expect(restored.importedAt, metadata.importedAt);
      expect(model.runtime, OnDeviceModelRuntime.llamaCpp);
      expect(model.format, OnDeviceModelFormat.gguf);
      expect(model.localPath, metadata.filePath);
      expect(model.fileName, 'Tiny-Llama.Q4.gguf');
      expect(model.isImported, isTrue);
      expect(model.isLlamaCpp, isTrue);
    });
  });

  group('ImportedGgufModelRepository', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('localmind_gguf_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loads saved metadata from versioned SharedPreferences key', () async {
      final metadata = _metadata(
        id: 'gguf-saved',
        filePath: '${tempDir.path}/saved.gguf',
      );
      final repository = await createRepository(
        initialValues: {
          storageKey: json.encode([metadata.toJson()]),
        },
      );

      final models = repository.load();

      expect(models, hasLength(1));
      expect(models.single.id, 'gguf-saved');
      expect(models.single.filePath, metadata.filePath);
    });

    test('delete removes metadata and the copied model file', () async {
      final file = File('${tempDir.path}/delete-me.gguf');
      await file.writeAsString('gguf bytes');
      final repository = await createRepository();
      await repository.saveAll([
        _metadata(id: 'gguf-delete-me', filePath: file.path),
      ]);

      await repository.delete('gguf-delete-me');

      expect(await file.exists(), isFalse);
      expect(repository.load(), isEmpty);
    });

    test('delete handles missing files gracefully', () async {
      final repository = await createRepository();
      await repository.saveAll([
        _metadata(id: 'gguf-missing', filePath: '${tempDir.path}/missing.gguf'),
      ]);

      await repository.delete('gguf-missing');

      expect(repository.load(), isEmpty);
    });

    test('loadExisting prunes stale metadata for missing files', () async {
      final file = File('${tempDir.path}/kept.gguf');
      await file.writeAsString('gguf bytes');
      final repository = await createRepository();
      await repository.saveAll([
        _metadata(id: 'gguf-kept', filePath: file.path),
        _metadata(id: 'gguf-stale', filePath: '${tempDir.path}/stale.gguf'),
      ]);

      final existing = await repository.loadExisting();

      expect(existing.map((model) => model.id), ['gguf-kept']);
      expect(repository.load().map((model) => model.id), ['gguf-kept']);
    });
  });
}

ImportedGgufModelMetadata _metadata({
  required String id,
  required String filePath,
}) {
  return ImportedGgufModelMetadata(
    id: id,
    name: 'Test GGUF',
    filePath: filePath,
    fileSizeBytes: 42,
    importedAt: DateTime.utc(2026, 6, 21),
  );
}
