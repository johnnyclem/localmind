import 'enums.dart';
import 'on_device_model_types.dart';

class ModelInfo {
  final String id;
  final String name;
  final String? description;
  final double? parameterCount;
  final int? contextLength;
  final int? fileSize;
  final String? quantization;
  final String? architecture;
  final ServerType serverType;
  final String serverId;
  final DateTime? modifiedAt;
  final ModelStatus status;
  final OnDeviceModelRuntime? onDeviceRuntime;
  final OnDeviceModelFormat? onDeviceFormat;
  final String? localPath;

  ModelInfo({
    required this.id,
    required this.name,
    this.description,
    this.parameterCount,
    this.contextLength,
    this.fileSize,
    this.quantization,
    this.architecture,
    required this.serverType,
    required this.serverId,
    this.modifiedAt,
    this.status = ModelStatus.unloaded,
    this.onDeviceRuntime,
    this.onDeviceFormat,
    this.localPath,
  });

  String get displayName {
    if (name.isNotEmpty) return name;
    return id
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  String? get formattedSize {
    if (fileSize == null || fileSize == 0) return null;
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String? get parameterCountDisplay {
    if (parameterCount == null) return null;
    final formatted = parameterCount!.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return '${parameterCount!.toInt()}B';
    } else if (formatted.endsWith('0')) {
      return '${parameterCount!.toStringAsFixed(1)}B';
    }
    return '${parameterCount!.toStringAsFixed(2)}B';
  }

  ModelInfo copyWith({
    String? id,
    String? name,
    String? description,
    double? parameterCount,
    int? contextLength,
    int? fileSize,
    String? quantization,
    String? architecture,
    ServerType? serverType,
    String? serverId,
    DateTime? modifiedAt,
    ModelStatus? status,
    OnDeviceModelRuntime? onDeviceRuntime,
    OnDeviceModelFormat? onDeviceFormat,
    String? localPath,
  }) {
    return ModelInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parameterCount: parameterCount ?? this.parameterCount,
      contextLength: contextLength ?? this.contextLength,
      fileSize: fileSize ?? this.fileSize,
      quantization: quantization ?? this.quantization,
      architecture: architecture ?? this.architecture,
      serverType: serverType ?? this.serverType,
      serverId: serverId ?? this.serverId,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      status: status ?? this.status,
      onDeviceRuntime: onDeviceRuntime ?? this.onDeviceRuntime,
      onDeviceFormat: onDeviceFormat ?? this.onDeviceFormat,
      localPath: localPath ?? this.localPath,
    );
  }
}
