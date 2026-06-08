import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsProvider extends ChangeNotifier {
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  Future<void> loadUnreadCount({
    required String token,
    required String userId,
  }) async {
    try {
      final data = await ApiService.get(
        '/notifications/user/$userId/unread',
        token: token,
      );
      final count =
          (data as Map<String, dynamic>)['count'] as int? ?? 0;
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearUnread() {
    if (_unreadCount != 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }
}
