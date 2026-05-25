import '../models/establishment.dart';
import '../core/constants.dart';
import '../services/api_service.dart';

abstract class IEstablishmentListRepository {
  Future<List<EstablishmentModel>> getAll();
}

class EstablishmentListRepository implements IEstablishmentListRepository {
  @override
  Future<List<EstablishmentModel>> getAll() async {
    final data = await ApiService.get(ApiConstants.establishmentsEndpoint);
    return (data as List)
        .map((e) => EstablishmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
