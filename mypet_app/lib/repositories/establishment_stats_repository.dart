import '../models/establishment_stats.dart';
import '../services/stats_service.dart';

abstract class IEstablishmentStatsRepository {
  Future<EstabStatsModel> fetch(
      {required String estabId, required String token});
}

class EstablishmentStatsRepository implements IEstablishmentStatsRepository {
  @override
  Future<EstabStatsModel> fetch(
          {required String estabId, required String token}) =>
      StatsService.fetchEstabStats(estabId: estabId, token: token);
}
