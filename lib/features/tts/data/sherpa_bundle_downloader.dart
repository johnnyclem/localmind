import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

Future<int> directorySize(Directory dir) async {
  var total = 0;
  if (!await dir.exists()) {
    return total;
  }

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      total += await entity.length();
    }
  }
  return total;
}

Future<void> extractTarBz2({
  required String archivePath,
  required Directory targetDir,
}) async {
  await Isolate.run(() => _extractTarBz2Sync(archivePath, targetDir.path));
}

void _extractTarBz2Sync(String archivePath, String targetDirPath) {
  final archiveBytes = File(archivePath).readAsBytesSync();
  final tarBytes = BZip2Decoder().decodeBytes(archiveBytes);
  final archive = TarDecoder().decodeBytes(tarBytes);

  for (final file in archive) {
    final relativePath = file.name;
    if (relativePath.isEmpty) continue;

    final outputPath = p.join(targetDirPath, relativePath);
    if (file.isFile) {
      final outputFile = File(outputPath);
      outputFile.createSync(recursive: true);
      outputFile.writeAsBytesSync(file.content as List<int>, flush: true);
    } else {
      Directory(outputPath).createSync(recursive: true);
    }
  }
}

Future<void> deleteDirectoryIfExists(Directory dir) async {
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
