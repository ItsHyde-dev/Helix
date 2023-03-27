import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/homepage.dart';

void main() async {
  AssetsAudioPlayer.setupNotificationsOpenAction((notification) {
    return true;
  });

  await Firebase.initializeApp();

  // ensure binder initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const Homepage());
}
