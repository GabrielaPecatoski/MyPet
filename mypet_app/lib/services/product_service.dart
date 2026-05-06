import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  static Future<List<ProductModel>> fetchAll({String? search}) async {
    final path = search != null && search.isNotEmpty
        ? '/marketplace/products?search=$search'
        : '/marketplace/products';
    final data = await ApiService.get(path);
    final list = data as List;
    return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<ProductModel>> fetchByEstab({
    required String estabId,
    required String token,
  }) async {
    final data = await ApiService.get(
      '/marketplace/establishments/$estabId/products',
      token: token,
    );
    final list = data as List;
    return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ProductModel> create({
    required String estabId,
    required String name,
    required String category,
    required double price,
    required int stock,
    required String token,
  }) async {
    final data = await ApiService.post(
      '/marketplace/establishments/$estabId/products',
      {'name': name, 'category': category, 'price': price, 'stock': stock},
      token: token,
    );
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<ProductModel> update({
    required String estabId,
    required String productId,
    required Map<String, dynamic> fields,
    required String token,
  }) async {
    final data = await ApiService.patch(
      '/marketplace/products/$productId',
      fields,
      token: token,
    );
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> delete({
    required String estabId,
    required String productId,
    required String token,
  }) async {
    await ApiService.delete('/marketplace/products/$productId', token: token);
  }
}
