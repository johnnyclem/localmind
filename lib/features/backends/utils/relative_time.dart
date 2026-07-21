/// Short relative-time label (e.g. "3h ago", "2d ago") for `last_used_at`.
/// No dependency pulled in for this — the ranges below are all this screen
/// needs.
String formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);

  if (diff.isNegative || diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '${m}m ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '${h}h ago';
  }
  if (diff.inDays < 30) {
    final d = diff.inDays;
    return '${d}d ago';
  }
  if (diff.inDays < 365) {
    final months = (diff.inDays / 30).floor();
    return '${months}mo ago';
  }
  final years = (diff.inDays / 365).floor();
  return '${years}y ago';
}
