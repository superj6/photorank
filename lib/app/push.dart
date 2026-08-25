import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_config.dart';
import '../data/arena/arena_api.dart';

/// Registers this device for Arena result pushes ("You finished #12").
/// No-op unless Firebase is configured for the build.
class Push {
  Push._();

  static bool _inited = false;

  static Future<void> register(ArenaApi api) async {
    if (!FirebaseConfig.configured || kIsWeb) return;
    try {
      if (!_inited) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: FirebaseConfig.apiKey,
            appId: FirebaseConfig.appId,
            messagingSenderId: FirebaseConfig.senderId,
            projectId: FirebaseConfig.projectId,
          ),
        );
        _inited = true;
      }
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      final token = await fm.getToken();
      if (token != null) await api.registerDeviceToken(token, platform: Platform.isIOS ? 'ios' : 'android');
      fm.onTokenRefresh.listen((t) => api.registerDeviceToken(t, platform: Platform.isIOS ? 'ios' : 'android'));
    } catch (e) {
      debugPrint('push registration failed: $e');
    }
  }
}
