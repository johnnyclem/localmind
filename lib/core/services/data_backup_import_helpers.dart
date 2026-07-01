String? backupImportString(Object? value) => value is String ? value : null;

DateTime? backupImportDateTime(Object? value) {
  final raw = backupImportString(value);
  if (raw == null) return null;
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return null;
  }
}
