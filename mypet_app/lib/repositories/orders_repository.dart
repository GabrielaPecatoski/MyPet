import '../services/order_service.dart';

abstract class IOrdersRepository {
  Future<List<Map<String, dynamic>>> getByUser(String userId, {String? token});
}

class OrdersRepository implements IOrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> getByUser(String userId, {String? token}) async {
    if (token == null) return [];
    return OrderService.fetchUserOrders(token: token, userId: userId);
  }
}
