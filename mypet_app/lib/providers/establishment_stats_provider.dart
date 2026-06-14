import 'package:flutter/material.dart';
import '../models/establishment_stats.dart';
import '../repositories/establishment_stats_repository.dart';

class EstablishmentStatsProvider extends ChangeNotifier {
  final IEstablishmentStatsRepository _repository;

  EstablishmentStatsProvider(this._repository);

  EstabStatsModel? _stats;
  bool _loading = false;
  String? _error;

  EstabStatsModel? get stats => _stats;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load({required String estabId, required String token}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _repository.fetch(estabId: estabId, token: token);
    } catch (_) {
      _error = 'Não foi possível carregar as estatísticas';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
