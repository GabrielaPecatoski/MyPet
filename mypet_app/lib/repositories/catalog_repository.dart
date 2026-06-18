import '../services/api_service.dart';
import '../core/constants.dart';

abstract class ICatalogRepository {
  Future<List<dynamic>> getAll({String? search});
}

class CatalogRepository implements ICatalogRepository {
  @override
  Future<List<dynamic>> getAll({String? search}) async {
    final path = search != null && search.isNotEmpty
        ? '${ApiConstants.productsEndpoint}?search=${Uri.encodeComponent(search)}'
        : ApiConstants.productsEndpoint;
    final data = await ApiService.get(path);
    return data as List<dynamic>;
  }
}
