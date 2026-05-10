import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/logger/app_logger.dart';
import 'kokoro_tts_model.dart';

/// Downloads Kokoro TTS model files (kokoro.onnx + voice .bin files)
/// from HuggingFace with resume support and per-file progress reporting.
class KokoroTtsDownloader {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _activeDownloads = {};

  Future<Directory> _getVariantDir(KokoroTtsModelVariant variant) async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/kokoro_tts/${variant.dirName}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Check whether all files for a variant have been downloaded.
  Future<bool> isVariantDownloaded(KokoroTtsModelVariant variant) async {
    final dir = await _getVariantDir(variant);
    final model = KokoroTtsModel.forVariant(variant);

    final modelPath = '${dir.path}/${model.modelFile.fileName}';
    if (!await File(modelPath).exists()) return false;

    for (final voice in model.voiceFiles) {
      final voicePath = '${dir.path}/${voice.fileName}';
      if (!await File(voicePath).exists()) return false;
    }
    return true;
  }

  /// Get total downloaded bytes for a variant.
  Future<int> getDownloadedBytes(KokoroTtsModelVariant variant) async {
    final dir = await _getVariantDir(variant);
    int total = 0;
    final entities = await dir.list().toList();
    for (final e in entities) {
      if (e is File) {
        total += await e.length();
      }
    }
    return total;
  }

  /// Download all files for [variant], emitting per-file progress.
  Stream<KokoroTtsFileProgress> downloadModel(KokoroTtsModelVariant variant) async* {
    final model = KokoroTtsModel.forVariant(variant);
    final dir = await _getVariantDir(variant);
    final variantKey = variant.name;

    await WakelockPlus.enable();

    try {
      final allFiles = <_DownloadableFile>[
        _DownloadableFile(
          fileName: model.modelFile.fileName,
          downloadUrl: model.modelFile.downloadUrl,
          sizeBytes: model.modelFile.sizeBytes,
        ),
        for (final voice in model.voiceFiles)
          _DownloadableFile(
            fileName: voice.fileName,
            downloadUrl: voice.downloadUrl,
            sizeBytes: voice.sizeBytes,
          ),
      ];

      for (final file in allFiles) {
        final cancelToken = CancelToken();
        _activeDownloads[variantKey] = cancelToken;

        final filePath = '${dir.path}/${file.fileName}';
        final partialPath = '$filePath.part';
        final partialFile = File(partialPath);

        int receivedBytes = 0;

        if (await partialFile.exists()) {
          receivedBytes = await partialFile.length();
          Log.info(
            'Resuming Kokoro ${variant.displayName} ${file.fileName} from $receivedBytes bytes',
          );
        }

        DateTime lastProgressUpdate = DateTime.now();

        try {
          final response = await _resolveWithRedirects(
            url: file.downloadUrl,
            startByte: receivedBytes,
            cancelToken: cancelToken,
          );

          final contentLenHeader =
              response.headers.value(Headers.contentLengthHeader);
          final totalBytes = contentLenHeader != null
              ? int.parse(contentLenHeader) + receivedBytes
              : file.sizeBytes;

          final IOSink sink = partialFile.openWrite(mode: FileMode.append);
          final stream = response.data?.stream;

          if (stream == null) {
            await sink.close();
            throw DioException(
              requestOptions: response.requestOptions,
              error: 'Response data stream is null',
            );
          }

          await for (final List<int> chunk in stream) {
            if (cancelToken.isCancelled) break;
            sink.add(chunk);
            receivedBytes += chunk.length;

            final now = DateTime.now();
            if (now.difference(lastProgressUpdate).inMilliseconds >= 500) {
              yield KokoroTtsFileProgress(
                fileName: file.fileName,
                variant: variant,
                receivedBytes: receivedBytes,
                totalBytes: totalBytes,
              );
              lastProgressUpdate = now;
            }
          }

          await sink.flush();
          await sink.close();

          await partialFile.rename(filePath);
          Log.info(
            'Kokoro ${variant.displayName} ${file.fileName} downloaded',
          );

          yield KokoroTtsFileProgress(
            fileName: file.fileName,
            variant: variant,
            receivedBytes: receivedBytes,
            totalBytes: receivedBytes,
            isComplete: true,
          );
        } catch (e) {
          if (e is DioException && CancelToken.isCancel(e)) {
            Log.info('Kokoro download cancelled for $variantKey');
            return;
          }
          rethrow;
        }
      }
    } finally {
      _activeDownloads.remove(variantKey);
      if (_activeDownloads.isEmpty) {
        await WakelockPlus.disable();
      }
    }
  }

  /// Cancel an in-flight download.
  void cancelDownload(KokoroTtsModelVariant variant) {
    _activeDownloads[variant.name]?.cancel();
  }

  /// Delete all files for a variant from disk.
  Future<void> deleteVariant(KokoroTtsModelVariant variant) async {
    final dir = await _getVariantDir(variant);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    Log.info('Kokoro variant ${variant.displayName} deleted');
  }

  /// Get list of downloaded variants.
  Future<Set<KokoroTtsModelVariant>> getDownloadedVariants() async {
    final result = <KokoroTtsModelVariant>{};
    for (final variant in KokoroTtsModelVariant.values) {
      if (await isVariantDownloaded(variant)) {
        result.add(variant);
      }
    }
    return result;
  }

  /// Get the absolute file path for a variant's model file.
  Future<String?> getModelPath(KokoroTtsModelVariant variant) async {
    final dir = await _getVariantDir(variant);
    final model = KokoroTtsModel.forVariant(variant);
    final file = File('${dir.path}/${model.modelFile.fileName}');
    if (await file.exists()) return file.path;
    return null;
  }

  /// Get the directory containing voice .bin files.
  Future<Directory> getVoicesDir(KokoroTtsModelVariant variant) async {
    return _getVariantDir(variant);
  }

  /// Manually follows redirects to ensure Authorization header safety.
  Future<Response<ResponseBody>> _resolveWithRedirects({
    required String url,
    required int startByte,
    required CancelToken cancelToken,
  }) async {
    String currentUrl = url;
    final Uri originalUri = Uri.parse(url);

    for (int hop = 0; hop < 5; hop++) {
      final options = Options(
        responseType: ResponseType.stream,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
        headers: {
          if (startByte > 0) 'Range': 'bytes=$startByte-',
        },
      );

      final currentUri = Uri.parse(currentUrl);
      if (currentUri.host != originalUri.host) {
        options.headers?.remove('Authorization');
      }

      final response = await _dio.get<ResponseBody>(
        currentUrl,
        options: options,
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        return response;
      }

      if (response.statusCode! >= 300 && response.statusCode! < 400) {
        final location = response.headers.value('location');
        if (location == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            error: 'Redirect without location header',
          );
        }
        currentUrl = Uri.parse(currentUrl).resolve(location).toString();
        continue;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Server returned ${response.statusCode}',
      );
    }

    throw DioException(
      requestOptions: RequestOptions(path: url),
      error: 'Too many redirects',
    );
  }
}

/// Internal helper for tracking files to download.
class _DownloadableFile {
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;

  const _DownloadableFile({
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
  });
}
