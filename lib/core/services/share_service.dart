import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._();

  static Future<void> shareText(String text, {String? subject}) async {
    if (text.trim().isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }
}
