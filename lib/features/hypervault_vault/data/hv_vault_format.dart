import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// UTF-8 byte length — the unit the server's `artifact_bytes` /
/// `source_prompt_chars` limits are actually enforced in.
int hvUtf8ByteLength(String text) => utf8.encode(text).length;

/// "3m ago" / "2h ago" / "5d ago", falling back to a locale date beyond a
/// week — mirrors the web dashboard's relative-date treatment.
String hvRelativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.yMMMd().format(dt);
}

/// Node/badge color by lowercased artifact `type`, byte-for-byte with the
/// web's `components/vault-graph.tsx` encoding (docs/mobile/prd/04-vault-graph.md).
Color hvArtifactTypeColor(String type, {bool isJsx = false}) {
  final t = type.toLowerCase();
  if (t == 'note') return const Color(0xFF34D399);
  if (isJsx || t == 'react' || t == 'jsx') return const Color(0xFF8B5CF6);
  if (t == 'game') return const Color(0xFFF472B6);
  if (t == 'report') return const Color(0xFFFBBF24);
  return const Color(0xFF60A5FA); // html + any unrecognized type
}
