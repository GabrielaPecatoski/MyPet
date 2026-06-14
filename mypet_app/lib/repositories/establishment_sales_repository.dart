import '../services/api_service.dart';

abstract class IEstablishmentSalesRepository {
  Future<List<Map<String, dynamic>>> fetchOrders(String estabId);
  Future<void> updateDeliveryStatus(String orderId, String status);
}

class EstablishmentSalesRepository implements IEstablishmentSalesRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchOrders(String estabId) async {
    final data =
        await ApiService.get('/marketplace/orders/establishment/$estabId');
    return (data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> updateDeliveryStatus(String orderId, String status) =>
      ApiService.patch(
        '/marketplace/orders/$orderId/delivery',
        {'deliveryStatus': status},
      );
}
