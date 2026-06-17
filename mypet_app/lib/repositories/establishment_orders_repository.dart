import '../services/order_service.dart';

abstract class IEstablishmentOrdersRepository {
  Future<List<Map<String, dynamic>>> fetchOrders(
      {required String estabId, required String token});
  Future<void> advance({required String orderId, required String token});
}

class EstablishmentOrdersRepository
    implements IEstablishmentOrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchOrders(
          {required String estabId, required String token}) =>
      OrderService.fetchEstabOrders(token: token, establishmentId: estabId);

  @override
  Future<void> advance({required String orderId, required String token}) =>
      OrderService.advance(token: token, orderId: orderId);
}
