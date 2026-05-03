import '../models/estab_stats.dart';
import '../models/admin_data.dart';
import '../services/stats_service.dart';

class StatsRepository {
  final String token;

  StatsRepository({required this.token});

  Future<EstabStatsModel> getEstabStats(String estabId) =>
      StatsService.fetchEstabStats(estabId: estabId, token: token);

  Future<AdminStatsModel> getAdminStats() =>
      StatsService.fetchAdminStats(token: token);
}
