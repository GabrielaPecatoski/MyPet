import 'package:flutter/material.dart';
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

  NotificationsProvider(this._repository);

  List<NotificationItem> _notifications = [];
  bool _loading = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _loading;

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
}
