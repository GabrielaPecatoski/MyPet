import '../services/api_service.dart';
import '../core/constants.dart';

abstract class IPaymentRepository {
  Future<String> createOrder(String userId);
  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> data);
}

class PaymentRepository implements IPaymentRepository {
  @override
  Future<String> createOrder(String userId) async {
    final res = await ApiService.post('${ApiConstants.ordersEndpoint}/$userId', {});
    return (res as Map<String, dynamic>)['id'] as String;
  }

  @override
  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> data) async {
    final res = await ApiService.post(ApiConstants.paymentsEndpoint, data);
    return res as Map<String, dynamic>;
  }
}
