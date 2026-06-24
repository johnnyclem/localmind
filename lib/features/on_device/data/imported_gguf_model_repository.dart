import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/on_device_model.dart';

class ImportedGgufModelMetadata {
  final String id;
  final String name;
  final String filePath;
  final int fileSizeBytes;
  final DateTime importedAt;

  const ImportedGgufModelMetadata({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileSizeBytes,
    required this.importedAt,
  });

  String get fileName => p.basename(filePath);

  OnDeviceModel toOnDeviceModel() {
    return OnDeviceModel(
      id: id,
      name: name,
      huggingFaceUrl: '',
      fileSizeBytes: fileSizeBytes,
      license: 'Local file',
      description: 'Imported GGUF model for local llama.cpp inference.',
      minRamMb: 2048,
      parameterLabel: 'GGUF',
      bestFor: 'Local GGUF inference',
      languagesLabel: 'Local',
      backendNote: 'llama.cpp',
      isCpuOnly: true,
      runtime: OnDeviceModelRuntime.llamaCpp,
      format: OnDeviceModelFormat.gguf,
      localPath: filePath,
      importedAt: importedAt,
      isImported: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'importedAt': importedAt.toIso8601String(),
    };
  }

  factory ImportedGgufModelMetadata.fromJson(Map<String, dynamic> json) {
    return ImportedGgufModelMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
      importedAt: DateTime.parse(json['importedAt'] as String),
    );
  }
}

class ImportedGgufModelRepository {
  static const _storageKey = 'imported_gguf_models_v1';
  static const _storageDirName = 'imported_gguf_models';

  final SharedPreferences _prefs;
  final Random _random;

  ImportedGgufModelRepository(this._prefs, {Random? random})
    : _random = random ?? Random.secure();

  List<ImportedGgufModelMetadata> load() {
    final encoded = _prefs.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return [];

    final decoded = json.decode(encoded) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              ImportedGgufModelMetadata.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ImportedGgufModelMetadata>> loadExisting() async {
    final models = load();
    final existing = <ImportedGgufModelMetadata>[];

    for (final model in models) {
      if (await File(model.filePath).exists()) {
        existing.add(model);
      }
    }

    if (existing.length != models.length) {
      await saveAll(existing);
    }

    return existing;
  }

  Future<ImportedGgufModelMetadata> importFromPath(String sourcePath) async {
    final source = File(sourcePath);
    if (!sourcePath.toLowerCase().endsWith('.gguf')) {
      throw const FormatException(
        'Only GGUF models are supported for this import.',
      );
    }
    if (!await source.exists()) {
      throw FileSystemException(
        'Selected model file does not exist',
        sourcePath,
      );
    }

    final dir = await _modelsDirectory();
    final originalName = p.basename(sourcePath);
    final id = _createId(originalName);
    final fileName = '$id-${_sanitizeFileName(originalName)}';
    final target = File(p.join(dir.path, fileName));
    await source.copy(target.path);

    final metadata = ImportedGgufModelMetadata(
      id: id,
      name: _displayNameFromFileName(originalName),
      filePath: target.path,
      fileSizeBytes: await target.length(),
      importedAt: DateTime.now(),
    );

    final current = load();
    await saveAll([...current, metadata]);
    return metadata;
  }

  Future<void> delete(String id) async {
    final current = load();
    final kept = <ImportedGgufModelMetadata>[];

    for (final model in current) {
      if (model.id == id) {
        final file = File(model.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } else {
        kept.add(model);
      }
    }

    await saveAll(kept);
  }

  Future<void> saveAll(List<ImportedGgufModelMetadata> models) async {
    final encoded = json.encode(models.map((m) => m.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  Future<Directory> _modelsDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, _storageDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _createId(String fileName) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final suffix = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'gguf-$micros-$suffix';
  }

  String _sanitizeFileName(String fileName) {
    final sanitized = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    if (sanitized.toLowerCase().endsWith('.gguf')) return sanitized;
    return '$sanitized.gguf';
  }

  String _displayNameFromFileName(String fileName) {
    final withoutExtension = fileName.replaceFirst(
      RegExp(r'\.gguf$', caseSensitive: false),
      '',
    );
    return withoutExtension
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
