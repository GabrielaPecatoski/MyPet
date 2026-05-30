import 'api_service.dart';

class OrderService {
  static Future<List<Map<String, dynamic>>> fetchUserOrders({
    required String token,
    required String userId,
  }) async {
    final data = await ApiService.get('/marketplace/orders/$userId', token: token);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> fetchEstabOrders({
    required String token,
    required String establishmentId,
  }) async {
    final data = await ApiService.get(
      '/marketplace/orders/establishment/$establishmentId',
      token: token,
    );
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> advance({
    required String token,
    required String orderId,
  }) async {
    final data = await ApiService.patch(
      '/marketplace/orders/$orderId/advance',
      {},
      token: token,
    );
    return data as Map<String, dynamic>;
  }
}
