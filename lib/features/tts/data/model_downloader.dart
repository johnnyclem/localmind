import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/models/enums.dart';

class ModelDownloader {
  Future<Directory> getTtsDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/tts_models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<bool> isEngineDownloaded(EngineId engine) async {
    final ttsDir = await getTtsDir();
    final engineDir = Directory('${ttsDir.path}/${engine.name}');
    if (!await engineDir.exists()) return false;
    final entities = await engineDir.list().toList();
    return entities.isNotEmpty;
  }
}
