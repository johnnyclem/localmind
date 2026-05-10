import 'package:flutter/material.dart';

/// Available Kokoro TTS model variants downloadable from HuggingFace.
enum KokoroTtsModelVariant {
  /// FP16 precision, ~170 MB total. Best quality.
  fp16,

  /// INT8 quantized, ~82 MB total. Faster, smaller.
  int8;

  String get displayName {
    switch (this) {
      case KokoroTtsModelVariant.fp16:
        return 'Kokoro TTS (FP16)';
      case KokoroTtsModelVariant.int8:
        return 'Kokoro TTS (Int8)';
    }
  }

  String get parameterLabel => '82M';

  /// Approximate total size in bytes.
  int get totalSizeBytes {
    switch (this) {
      case KokoroTtsModelVariant.fp16:
        return 170 * 1024 * 1024;
      case KokoroTtsModelVariant.int8:
        return 82 * 1024 * 1024;
    }
  }

  String get description {
    switch (this) {
      case KokoroTtsModelVariant.fp16:
        return 'Highest quality with 22 voices. Requires ~250 MB RAM.';
      case KokoroTtsModelVariant.int8:
        return 'Smaller, faster model with excellent quality. Recommended.';
    }
  }

  bool get isRecommended => this == KokoroTtsModelVariant.int8;

  String get huggingFaceRepoId {
    switch (this) {
      case KokoroTtsModelVariant.fp16:
        return 'onnx-community/Kokoro-82M-ONNX';
      case KokoroTtsModelVariant.int8:
        return 'palshub/kokoro-82m-v1.0-int8';
    }
  }

  /// Storage directory name for this variant.
  String get dirName => 'kokoro_$name';
}

/// Voice metadata for a single Kokoro voice file.
@immutable
class KokoroVoiceFile {
  final String voiceId;
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;

  const KokoroVoiceFile({
    required this.voiceId,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
  });
}

/// Metadata for the main Kokoro model file.
@immutable
class KokoroModelFile {
  final String fileName;
  final String downloadUrl;
  final int sizeBytes;

  const KokoroModelFile({
    required this.fileName,
    required this.downloadUrl,
    required this.sizeBytes,
  });
}

/// A fully-specified Kokoro TTS model with variant, model file, and voices.
@immutable
class KokoroTtsModel {
  final KokoroTtsModelVariant variant;
  final KokoroModelFile modelFile;
  final List<KokoroVoiceFile> voiceFiles;
  final int totalSizeBytes;

  const KokoroTtsModel({
    required this.variant,
    required this.modelFile,
    required this.voiceFiles,
    required this.totalSizeBytes,
  });

  static const List<String> _voiceIds = [
    'af_heart',
    'af_bella',
    'af_nicole',
    'af_aoihana',
    'af_sarah',
    'af_sky',
    'am_adam',
    'am_michael',
    'bf_isabelle',
    'bf_alice',
    'bm_george',
    'bm_lewis',
  ];

  static KokoroTtsModel forVariant(KokoroTtsModelVariant variant) {
    final repo = variant.huggingFaceRepoId;
    final modelPath =
        variant == KokoroTtsModelVariant.fp16 ? 'onnx/model.onnx' : 'kokoro.onnx';

    final modelFile = KokoroModelFile(
      fileName: 'kokoro.onnx',
      downloadUrl:
          'https://huggingface.co/$repo/resolve/main/$modelPath',
      sizeBytes: variant == KokoroTtsModelVariant.fp16
          ? 166 * 1024 * 1024
          : 78 * 1024 * 1024,
    );

    final voiceFiles = _voiceIds.map((id) {
      final voicePath =
          variant == KokoroTtsModelVariant.fp16 ? 'voices/$id.bin' : '$id.bin';
      return KokoroVoiceFile(
        voiceId: id,
        fileName: '$id.bin',
        downloadUrl:
            'https://huggingface.co/$repo/resolve/main/$voicePath',
        sizeBytes: 175 * 1024,
      );
    }).toList();

    return KokoroTtsModel(
      variant: variant,
      modelFile: modelFile,
      voiceFiles: voiceFiles,
      totalSizeBytes: variant.totalSizeBytes,
    );
  }

  static final List<KokoroTtsModel> allModels =
      KokoroTtsModelVariant.values.map(forVariant).toList();

  String get displayName => variant.displayName;

  String get parameterLabel => variant.parameterLabel;

  String get description => variant.description;

  bool get isRecommended => variant.isRecommended;
}

/// Progress for downloading a single Kokoro file (model or voice).
@immutable
class KokoroTtsFileProgress {
  final String fileName;
  final KokoroTtsModelVariant variant;
  final int receivedBytes;
  final int totalBytes;
  final bool isComplete;

  const KokoroTtsFileProgress({
    required this.fileName,
    required this.variant,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.isComplete = false,
  });

  double get fraction =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
}
