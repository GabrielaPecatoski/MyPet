import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sse_notification_client.dart';

class NotificationsProvider extends ChangeNotifier {
  int _unreadCount = 0;
  final _sse = SseNotificationClient();

  int get unreadCount => _unreadCount;

  /// Busca a contagem atual do servidor (usado como estado inicial e fallback).
  Future<void> loadUnreadCount({
    required String token,
    required String userId,
  }) async {
    try {
      final data = await ApiService.get(
        '/notifications/user/$userId/unread',
        token: token,
      );
      final count = (data as Map<String, dynamic>)['count'] as int? ?? 0;
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Abre o SSE do servidor e incrementa o badge a cada notificação recebida.
  /// Chame uma única vez após login — o cliente reconecta sozinho se cair.
  void startStream({required String userId, required String token}) {
    _sse.connect(
      userId: userId,
      token: token,
      onEvent: (event) {
        // 'ping' é o heartbeat de 25 s — ignorar
        if (event['type'] == 'ping') return;
        _unreadCount++;
        notifyListeners();
      },
    );
  }

  /// Para o SSE (chame no logout ou no dispose do widget raiz).
  void stopStream() => _sse.close();

  /// Zera o badge localmente após o usuário visualizar as notificações.
  void clearUnread() {
    if (_unreadCount != 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sse.close();
    super.dispose();
  }
}
