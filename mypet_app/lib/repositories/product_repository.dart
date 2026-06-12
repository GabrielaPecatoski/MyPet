import '../models/product.dart';
import '../services/product_service.dart';

class ProductRepository {
  final String estabId;
  final String token;

  ProductRepository({required this.estabId, required this.token});

  Future<List<ProductModel>> getAll() => ProductService.fetchByEstab(
        estabId: estabId,
        token: token,
      );

  Future<ProductModel> create({
    required String name,
    required String category,
    required double price,
    required int stock,
  }) =>
      ProductService.create(
        estabId: estabId,
        name: name,
        category: category,
        price: price,
        stock: stock,
        token: token,
      );

  Future<ProductModel> update({
    required String productId,
    required Map<String, dynamic> fields,
  }) =>
      ProductService.update(
        estabId: estabId,
        productId: productId,
        fields: fields,
        token: token,
      );

  Future<void> delete(String productId) => ProductService.delete(
        estabId: estabId,
        productId: productId,
        token: token,
      );
}
