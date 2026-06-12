import '../models/admin_data.dart';
import 'api_service.dart';

class AdminService {
  static Future<List<AdminUserModel>> fetchUsers({required String token}) async {
    final data = await ApiService.get('/auth/admin/users', token: token);
    final list = data as List;
    return list.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> deleteUser({
    required String userId,
    required String token,
  }) async {
    await ApiService.delete('/auth/admin/users/$userId', token: token);
  }

  static Future<List<AdminEstabModel>> fetchEstablishments({required String token}) async {
    final data = await ApiService.get('/establishments/admin/all', token: token);
    final list = data as List;
    return list.map((e) => AdminEstabModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
