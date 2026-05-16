enum PiperTtsModelVariant { enUsLessacMedium, enUsRyanMedium }

extension PiperTtsModelVariantExtension on PiperTtsModelVariant {
  String get id {
    switch (this) {
      case PiperTtsModelVariant.enUsLessacMedium:
        return 'en_US-lessac-medium';
      case PiperTtsModelVariant.enUsRyanMedium:
        return 'en_US-ryan-medium';
    }
  }

  String get displayName {
    switch (this) {
      case PiperTtsModelVariant.enUsLessacMedium:
        return 'English (US) - Lessac (Medium)';
      case PiperTtsModelVariant.enUsRyanMedium:
        return 'English (US) - Ryan (Medium)';
    }
  }

  String get modelFileName => '$id.onnx';
  String get configFileName => '$id.onnx.json';
  String get bundleDirName {
    return 'vits-piper-$id';
  }

  String get tarballUrl =>
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/$bundleDirName.tar.bz2';

  String get tokensFileName => 'tokens.txt';
  String get dataDirName => 'espeak-ng-data';

  int get totalSizeBytes {
    switch (this) {
      case PiperTtsModelVariant.enUsLessacMedium:
      case PiperTtsModelVariant.enUsRyanMedium:
        return 60 * 1024 * 1024;
    }
  }

  bool get isRecommended => this == PiperTtsModelVariant.enUsLessacMedium;
}

class PiperTtsFileProgress {
  final String fileName;
  final int receivedBytes;
  final int totalBytes;
  final bool isComplete;

  const PiperTtsFileProgress({
    required this.fileName,
    required this.receivedBytes,
    required this.totalBytes,
    required this.isComplete,
  });

  double get fraction {
    if (totalBytes <= 0) return 0;
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }
}
