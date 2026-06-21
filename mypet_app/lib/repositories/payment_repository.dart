import '../services/api_service.dart';
import '../core/constants.dart';

abstract class IPaymentRepository {
  Future<String> createOrder(String userId, {String? token});
  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> data, {String? token});
  Future<Map<String, dynamic>> processBookingPayment({
    required String bookingId,
    required String method,
    String? cardNumber,
    int? installments,
    required String token,
  });
}

class PaymentRepository implements IPaymentRepository {
  @override
  Future<String> createOrder(String userId, {String? token}) async {
    final res = await ApiService.post('${ApiConstants.ordersEndpoint}/$userId', {}, token: token);
    return (res as Map<String, dynamic>)['id'] as String;
  }

  @override
  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> data, {String? token}) async {
    final res = await ApiService.post(ApiConstants.paymentsEndpoint, data, token: token);
    return res as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> processBookingPayment({
    required String bookingId,
    required String method,
    String? cardNumber,
    int? installments,
    required String token,
  }) async {
    final endpoint = ApiConstants.bookingPaymentEndpoint.replaceAll('{id}', bookingId);
    final body = {
      'method': method,
      'cardNumber': ?cardNumber,
      'installments': ?installments,
    };
    try {
      final res = await ApiService.patch(endpoint, body, token: token);
      return res as Map<String, dynamic>;
    } catch (e) {
      if (ApiService.isNetworkError(e)) {
        final res = await ApiService.patch(endpoint, body, token: token);
        return res as Map<String, dynamic>;
      }
      rethrow;
    }
  }
}
