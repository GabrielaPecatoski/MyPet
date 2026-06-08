import '../services/api_service.dart';

class AdminRepository {
  final String token;

  AdminRepository({required this.token});

  Future<List<Map<String, dynamic>>> getUsers() async {
    final data = await ApiService.get('/auth/admin/users', token: token);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
