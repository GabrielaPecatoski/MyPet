import '../core/constants.dart';
import 'api_service.dart';

class CartService {
  static Future<List<dynamic>> getCart(String userId, {String? token}) async {
    final data = await ApiService.get(
      '${ApiConstants.cartEndpoint}/$userId',
      token: token,
    );
    return data as List<dynamic>;
  }

  static Future<void> addItem(
    String userId,
    String productId,
    int quantity, {
    String? token,
  }) async {
    await ApiService.post(
      '${ApiConstants.cartEndpoint}/$userId',
      {'productId': productId, 'quantity': quantity},
      token: token,
    );
  }

  static Future<void> updateItem(
    String userId,
    String productId,
    int quantity, {
    String? token,
  }) async {
    await ApiService.patch(
      '${ApiConstants.cartEndpoint}/$userId/$productId',
      {'quantity': quantity},
      token: token,
    );
  }

  static Future<void> removeItem(
    String userId,
    String productId, {
    String? token,
  }) async {
    await ApiService.delete(
      '${ApiConstants.cartEndpoint}/$userId/$productId',
      token: token,
    );
  }

  static Future<void> clearCart(String userId, {String? token}) async {
    await ApiService.delete(
      '${ApiConstants.cartEndpoint}/$userId',
      token: token,
    );
  }
}
