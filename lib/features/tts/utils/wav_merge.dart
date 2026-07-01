import 'dart:typed_data';

/// Merges multiple PCM WAV files (same format) into a single WAV.
Uint8List mergeWavFiles(List<Uint8List> wavFiles) {
  if (wavFiles.isEmpty) return Uint8List(0);
  if (wavFiles.length == 1) return wavFiles.first;

  final first = wavFiles.first;
  final dataOffset = _findPcmDataOffset(first);
  if (dataOffset == null) return first;

  final dataSizeOffset = _findDataChunkSizeOffset(first);

  final pcmBuilder = BytesBuilder(copy: false);
  for (final wav in wavFiles) {
    final offset = _findPcmDataOffset(wav);
    if (offset != null && wav.length > offset) {
      pcmBuilder.add(wav.sublist(offset));
    }
  }
  final pcmData = pcmBuilder.toBytes();

  final header = Uint8List.fromList(first.sublist(0, dataOffset));
  _writeUint32LE(header, 4, header.length + pcmData.length - 8);
  if (dataSizeOffset != null) {
    _writeUint32LE(header, dataSizeOffset, pcmData.length);
  }

  return Uint8List.fromList([...header, ...pcmData]);
}

int? _findPcmDataOffset(Uint8List wav) {
  final dataSizeOffset = _findDataChunkSizeOffset(wav);
  return dataSizeOffset == null ? null : dataSizeOffset + 4;
}

int? _findDataChunkSizeOffset(Uint8List wav) {
  if (wav.length < 12) return null;
  if (wav[0] != 0x52 ||
      wav[1] != 0x49 ||
      wav[2] != 0x46 ||
      wav[3] != 0x46 ||
      wav[8] != 0x57 ||
      wav[9] != 0x41 ||
      wav[10] != 0x56 ||
      wav[11] != 0x45) {
    return null;
  }

  var offset = 12;
  while (offset + 8 <= wav.length) {
    final chunkId = String.fromCharCodes(wav.sublist(offset, offset + 4));
    final chunkSize = _readUint32LE(wav, offset + 4);
    if (chunkId == 'data') {
      return offset + 4;
    }
    offset += 8 + chunkSize;
    if (chunkSize.isOdd) offset++;
  }
  return null;
}

int _readUint32LE(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

void _writeUint32LE(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
  bytes[offset + 3] = (value >> 24) & 0xff;
}
