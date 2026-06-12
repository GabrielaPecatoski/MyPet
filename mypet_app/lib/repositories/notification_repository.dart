import '../services/api_service.dart';

abstract class INotificationRepository {
  Future<List<Map<String, dynamic>>> getByUser(String userId, {String? token});
  Future<void> markAllRead(String userId, {String? token});
}

class NotificationRepository implements INotificationRepository {
  @override
  Future<List<Map<String, dynamic>>> getByUser(String userId, {String? token}) async {
    final data = await ApiService.get('/notifications/user/$userId', token: token);
    return (data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> markAllRead(String userId, {String? token}) =>
      ApiService.patch('/notifications/user/$userId/read-all', {}, token: token);
}
