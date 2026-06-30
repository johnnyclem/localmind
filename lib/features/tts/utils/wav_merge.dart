import 'dart:typed_data';

/// Merges multiple PCM WAV files (same format) into a single WAV.
Uint8List mergeWavFiles(List<Uint8List> wavFiles) {
  if (wavFiles.isEmpty) return Uint8List(0);
  if (wavFiles.length == 1) return wavFiles.first;

  final first = wavFiles.first;
  if (first.length < 44) return first;

  final pcmBuilder = BytesBuilder(copy: false);
  for (final wav in wavFiles) {
    if (wav.length > 44) {
      pcmBuilder.add(wav.sublist(44));
    }
  }
  final pcmData = pcmBuilder.toBytes();
  final totalSize = 36 + pcmData.length;

  final merged = ByteData(44);
  merged.setUint8(0, 0x52); // R
  merged.setUint8(1, 0x49); // I
  merged.setUint8(2, 0x46); // F
  merged.setUint8(3, 0x46); // F
  merged.setUint32(4, totalSize, Endian.little);
  merged.setUint8(8, 0x57); // W
  merged.setUint8(9, 0x41); // A
  merged.setUint8(10, 0x56); // V
  merged.setUint8(11, 0x45); // E

  // Copy fmt chunk from first file (bytes 12-35)
  for (var i = 12; i < 36; i++) {
    merged.setUint8(i, first[i]);
  }

  merged.setUint8(36, 0x64); // d
  merged.setUint8(37, 0x61); // a
  merged.setUint8(38, 0x74); // t
  merged.setUint8(39, 0x61); // a
  merged.setUint32(40, pcmData.length, Endian.little);

  return Uint8List.fromList([
    ...merged.buffer.asUint8List(),
    ...pcmData,
  ]);
}
