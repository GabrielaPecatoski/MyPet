import '../models/estab_stats.dart';
import '../models/admin_data.dart';
import 'api_service.dart';

class StatsService {
  static Future<EstabStatsModel> fetchEstabStats({
    required String estabId,
    required String token,
  }) async {
    final data = await ApiService.get('/establishments/$estabId/stats', token: token);
    return EstabStatsModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<AdminStatsModel> fetchAdminStats({required String token}) async {
    final data = await ApiService.get('/establishments/admin/stats', token: token);
    return AdminStatsModel.fromJson(data as Map<String, dynamic>);
  }
}
