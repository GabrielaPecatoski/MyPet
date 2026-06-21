import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PushNotificationService {
  static bool _initialized = false;

  static Future<void> init({
    required String token,
    required String userId,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final fcmToken = await messaging.getToken();
      if (fcmToken == null) return;

      final platform = kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : 'android';

      await ApiService.post(
        '/notifications/device-token',
        {'userId': userId, 'token': fcmToken, 'platform': platform},
        token: token,
      );

      _initialized = true;

      messaging.onTokenRefresh.listen((newToken) async {
        try {
          await ApiService.post(
            '/notifications/device-token',
            {'userId': userId, 'token': newToken, 'platform': platform},
            token: token,
          );
        } catch (_) {}
      });
    } catch (_) {
      // Firebase não configurado ou sem permissão — ignorar silenciosamente
    }
  }

  static Future<void> unregister({
    required String userId,
    required String token,
  }) async {
    if (!_initialized) return;
    try {
      await ApiService.delete(
        '/notifications/device-token/$userId',
        token: token,
      );
      _initialized = false;
    } catch (_) {}
  }
}
