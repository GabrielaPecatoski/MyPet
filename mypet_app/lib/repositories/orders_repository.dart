import '../services/api_service.dart';
import '../core/constants.dart';

abstract class IOrdersRepository {
  Future<List<Map<String, dynamic>>> getByUser(String userId);
}

class OrdersRepository implements IOrdersRepository {
  @override
  Future<List<Map<String, dynamic>>> getByUser(String userId) async {
    final data = await ApiService.get('${ApiConstants.paymentsEndpoint}/user/$userId');
    return (data as List).cast<Map<String, dynamic>>();
  }
}
