import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'bootstrap/bootstrap_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.abdulmominsakib.localmind.channel.audio',
    androidNotificationChannelName: 'LocalMind Audio TTS Playback',
    androidNotificationOngoing: true,
  );
  runApp(const BootstrapHost());
}
