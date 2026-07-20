import 'package:shared_preferences/shared_preferences.dart';

/// Maps a local LocalMind conversation id to the HyperVault-side
/// `conversation_id` it continues, so `POST /api/chat` (via
/// [HyperVaultChatService]) appends to the same server-side conversation on
/// every turn instead of starting a fresh one each time. Deliberately kept
/// outside the ObjectBox schema — this is a thin, append-only local cache,
/// not a source of truth (HyperVault's conversation history is).
class HyperVaultConversationLinkService {
  static const _prefix = 'hvConvLink_';

  final SharedPreferences _prefs;

  HyperVaultConversationLinkService(this._prefs);

  String? remoteIdFor(String? localConversationId) {
    if (localConversationId == null) return null;
    return _prefs.getString('$_prefix$localConversationId');
  }

  Future<void> link(String localConversationId, String remoteConversationId) {
    return _prefs.setString(
      '$_prefix$localConversationId',
      remoteConversationId,
    );
  }

  Future<void> unlink(String localConversationId) {
    return _prefs.remove('$_prefix$localConversationId');
  }
}
