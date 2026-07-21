import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/hypervault_providers.dart';
import '../data/import_history_api_service.dart';

final importHistoryApiServiceProvider = Provider<ImportHistoryApiService>((
  ref,
) {
  return ImportHistoryApiService(ref.watch(hypervaultClientProvider));
});

/// Platform choices for the import screen (mobile PRD T-M12-02).
///
/// [apiValue] is what's sent as the `platform` field on `/api/import`;
/// `null` (auto-detect) omits the field entirely so the server sniffs it.
enum ImportPlatform {
  auto,
  chatgpt,
  claude,
  gemini,
  grok;

  String get label => switch (this) {
    ImportPlatform.auto => 'Auto-detect',
    ImportPlatform.chatgpt => 'ChatGPT',
    ImportPlatform.claude => 'Claude',
    ImportPlatform.gemini => 'Gemini',
    ImportPlatform.grok => 'Grok',
  };

  String? get apiValue => switch (this) {
    ImportPlatform.auto => null,
    ImportPlatform.chatgpt => 'chatgpt',
    ImportPlatform.claude => 'claude',
    ImportPlatform.gemini => 'gemini',
    ImportPlatform.grok => 'grok',
  };

  /// "Where to get your export" copy (mobile PRD T-M12-06), mirroring the
  /// web import page's guidance for each platform.
  String get instructions => switch (this) {
    ImportPlatform.auto =>
      "We'll inspect the file or paste and detect ChatGPT, Claude, Gemini, "
          'or Grok automatically. Anything else — paste raw text with '
          'User:/Assistant: labels and we\'ll parse it as a transcript.',
    ImportPlatform.chatgpt =>
      'ChatGPT: Settings → Data controls → Export data, then unzip the '
          'download and pick conversations.json.',
    ImportPlatform.claude =>
      'Claude: Settings → Privacy → Export data, then unzip the download '
          'and pick conversations.json.',
    ImportPlatform.gemini =>
      'Gemini: Google Takeout → select Gemini Apps → Create export, then '
          'unzip the download and pick MyActivity.json.',
    ImportPlatform.grok =>
      'Grok: on X, go to Settings → Your account → Download an archive of '
          'your data, then unzip it and pick the conversations file inside.',
  };
}
