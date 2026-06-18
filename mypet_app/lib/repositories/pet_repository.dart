import '../models/pet.dart';
import '../services/api_service.dart';

abstract class IPetRepository {
  Future<List<PetModel>> getByUser(String userId, {String? token});
  Future<PetModel> create(String userId, Map<String, dynamic> data, {String? token});
  Future<PetModel> update(String petId, Map<String, dynamic> data, {String? token});
  Future<void> delete(String petId, {String? token});
}

class PetRepository implements IPetRepository {
  @override
  Future<List<PetModel>> getByUser(String userId, {String? token}) async {
    final data = await ApiService.get('/pets/user/$userId', token: token);
    return (data as List).map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PetModel> create(String userId, Map<String, dynamic> data, {String? token}) async {
    final res = await ApiService.post('/pets/user/$userId', data, token: token);
    return PetModel.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<PetModel> update(String petId, Map<String, dynamic> data, {String? token}) async {
    await ApiService.patch('/pets/$petId', data, token: token);
    return PetModel.fromJson({...data, 'id': petId});
  }

  @override
  Future<void> delete(String petId, {String? token}) =>
      ApiService.delete('/pets/$petId', token: token);
}
