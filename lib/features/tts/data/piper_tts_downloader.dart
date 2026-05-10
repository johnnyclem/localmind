import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'model_downloader.dart';
import 'piper_tts_model.dart';

class PiperTtsDownloader {
  final Dio _dio;
  final ModelDownloader _baseDownloader;
  final Map<PiperTtsModelVariant, CancelToken> _cancelTokens = {};

  PiperTtsDownloader()
      : _dio = Dio(),
        _baseDownloader = ModelDownloader();

  Future<Directory> _getVariantDir(PiperTtsModelVariant variant) async {
    final ttsDir = await _baseDownloader.getTtsDir();
    final dir = Directory('${ttsDir.path}/piper');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Set<PiperTtsModelVariant>> getDownloadedVariants() async {
    final downloaded = <PiperTtsModelVariant>{};
    for (final variant in PiperTtsModelVariant.values) {
      final dir = await _getVariantDir(variant);
      final modelFile = File('${dir.path}/${variant.modelFileName}');
      final configFile = File('${dir.path}/${variant.configFileName}');
      if (await modelFile.exists() && await configFile.exists()) {
        downloaded.add(variant);
      }
    }
    return downloaded;
  }

  Stream<PiperTtsFileProgress> downloadModel(
    PiperTtsModelVariant variant,
  ) async* {
    final cancelToken = CancelToken();
    _cancelTokens[variant] = cancelToken;

    try {
      final dir = await _getVariantDir(variant);

      // Download .onnx
      yield* _downloadFile(
        variant.modelUrl,
        '${dir.path}/${variant.modelFileName}',
        variant.modelFileName,
        cancelToken,
      );

      // Download .onnx.json
      yield* _downloadFile(
        variant.configUrl,
        '${dir.path}/${variant.configFileName}',
        variant.configFileName,
        cancelToken,
      );
    } finally {
      _cancelTokens.remove(variant);
    }
  }

  Stream<PiperTtsFileProgress> _downloadFile(
    String url,
    String savePath,
    String fileName,
    CancelToken cancelToken,
  ) async* {
    // Optional: if it already exists and has size > 0, we could skip it.
    // For simplicity, we just redownload to ensure it's complete,
    // or you could check file size. We'll do a simple redownload.

    int totalBytes = 1; // dummy initial
    int receivedBytes = 0;

    final controller = StreamController<PiperTtsFileProgress>();

    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            totalBytes = total;
          } else if (totalBytes == 1) {
            // Give it some arbitrary size if server doesn't report
            totalBytes = 10 * 1024 * 1024;
          }
          receivedBytes = received;

          if (!controller.isClosed) {
            controller.add(
              PiperTtsFileProgress(
                fileName: fileName,
                receivedBytes: receivedBytes,
                totalBytes: totalBytes,
                isComplete: false,
              ),
            );
          }
        },
      );

      if (!controller.isClosed) {
        controller.add(
          PiperTtsFileProgress(
            fileName: fileName,
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
            isComplete: true,
          ),
        );
      }
    } catch (e) {
      if (e is! DioException || !CancelToken.isCancel(e)) {
        rethrow;
      }
    } finally {
      await controller.close();
    }

    yield* controller.stream;
  }

  void cancelDownload(PiperTtsModelVariant variant) {
    _cancelTokens[variant]?.cancel('User cancelled');
    _cancelTokens.remove(variant);
  }

  Future<void> deleteVariant(PiperTtsModelVariant variant) async {
    final dir = await _getVariantDir(variant);
    final modelFile = File('${dir.path}/${variant.modelFileName}');
    final configFile = File('${dir.path}/${variant.configFileName}');
    if (await modelFile.exists()) await modelFile.delete();
    if (await configFile.exists()) await configFile.delete();
  }
}
