import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sse_notification_client.dart';
import '../repositories/notification_repository.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        type: json['type'] ?? 'INFO',
        read: json['read'] ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class NotificationsProvider extends ChangeNotifier {
  final INotificationRepository _repository;
  final _sse = SseNotificationClient();

  int _unreadCount = 0;
  List<NotificationItem> _notifications = [];
  bool _loading = false;

  NotificationsProvider(this._repository);

  int get unreadCount => _unreadCount;
  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _loading;

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

  Future<void> load(String userId, {String? token}) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _repository.getByUser(userId, token: token);
      _notifications = data.map(NotificationItem.fromJson).toList();
      await _repository.markAllRead(userId, token: token);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sse.close();
    super.dispose();
  }
}
