import '../models/product.dart';
import '../services/api_service.dart';

abstract class IEstablishmentProductsRepository {
  Future<String?> ownerEstablishmentId(String ownerId, {String? token});
  Future<List<ProductModel>> fetchProducts(String estabId, {String? token});
  Future<void> create(Map<String, dynamic> body, {String? token});
  Future<void> update(String productId, Map<String, dynamic> body,
      {String? token});
  Future<void> setActive(String productId, bool active, {String? token});
  Future<void> delete(String productId, {String? token});
}

class EstablishmentProductsRepository
    implements IEstablishmentProductsRepository {
  @override
  Future<String?> ownerEstablishmentId(String ownerId, {String? token}) async {
    final data =
        await ApiService.get('/establishments/owner/$ownerId', token: token);
    final estabs = data is List ? data : [data];
    if (estabs.isEmpty) return null;
    return (estabs.first as Map<String, dynamic>)['id'] as String?;
  }

  @override
  Future<List<ProductModel>> fetchProducts(String estabId,
      {String? token}) async {
    final data = await ApiService.get(
      '/marketplace/products/establishment/$estabId',
      token: token,
    );
    return (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> create(Map<String, dynamic> body, {String? token}) =>
      ApiService.post('/marketplace/products', body, token: token);

  @override
  Future<void> update(String productId, Map<String, dynamic> body,
          {String? token}) =>
      ApiService.patch('/marketplace/products/$productId', body, token: token);

  @override
  Future<void> setActive(String productId, bool active, {String? token}) =>
      ApiService.patch('/marketplace/products/$productId', {'active': active},
          token: token);

  @override
  Future<void> delete(String productId, {String? token}) =>
      ApiService.delete('/marketplace/products/$productId', token: token);
}
