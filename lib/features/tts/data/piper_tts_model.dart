
enum PiperTtsModelVariant {
  enUsLessacMedium,
  enUsRyanMedium,
}

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

  String get modelUrl {
    switch (this) {
      case PiperTtsModelVariant.enUsLessacMedium:
        return 'https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx';
      case PiperTtsModelVariant.enUsRyanMedium:
        return 'https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx';
    }
  }

  String get configUrl {
    switch (this) {
      case PiperTtsModelVariant.enUsLessacMedium:
        return 'https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json';
      case PiperTtsModelVariant.enUsRyanMedium:
        return 'https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx.json';
    }
  }

  int get totalSizeBytes {
    switch (this) {
      case PiperTtsModelVariant.enUsLessacMedium:
        return 48 * 1024 * 1024; // ~48MB
      case PiperTtsModelVariant.enUsRyanMedium:
        return 48 * 1024 * 1024; // ~48MB
    }
  }
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
