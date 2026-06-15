import '../services/order_service.dart';

abstract class IOrdersRepository {
  Future<List<Map<String, dynamic>>> getByUser(String userId, {String? token});
  Future<List<Map<String, dynamic>>> getByEstablishment(String establishmentId,
      {String? token});
}

class OrdersRepository implements IOrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> getByUser(String userId, {String? token}) async {
    if (token == null) return [];
    return OrderService.fetchUserOrders(token: token, userId: userId);
  }

  @override
  Future<List<Map<String, dynamic>>> getByEstablishment(String establishmentId,
      {String? token}) async {
    if (token == null) return [];
    return OrderService.fetchEstabOrders(
        token: token, establishmentId: establishmentId);
  }
}
