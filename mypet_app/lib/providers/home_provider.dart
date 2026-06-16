import 'package:flutter/material.dart';
import '../models/establishment.dart';
import '../models/veterinarian.dart';
import '../repositories/establishment_list_repository.dart';
import '../services/veterinarian_service.dart';

class HomeProvider extends ChangeNotifier {
  final IEstablishmentListRepository _repository;

  HomeProvider(this._repository);

  List<EstablishmentModel> _all = [];
  List<EstablishmentModel> _filtered = [];
  List<VeterinarianModel> _availableVets = [];
  bool _loading = false;
  bool _loadingVets = false;
  String? _error;

  String _query = '';
  String _typeFilter = 'Todos';

  List<EstablishmentModel> get establishments => _filtered;
  List<VeterinarianModel> get availableVets => _availableVets;
  bool get isLoading => _loading;
  bool get loadingVets => _loadingVets;
  String? get error => _error;

  /// Estabelecimentos em destaque: os mais bem avaliados dentro do
  /// filtro/busca atual, ordenados por nota decrescente.
  List<EstablishmentModel> get highlights {
    final list = List<EstablishmentModel>.of(_filtered)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(5).toList();
  }

  /// Distância aproximada (em km) de um estabelecimento até o usuário.
  ///
  /// O sistema não armazena coordenadas, então derivamos um valor estável a
  /// partir do `id` (determinístico, não muda entre rebuilds) só para alimentar
  /// a seção "Próximos a você". Faixa: ~0,3 a ~9,7 km.
  static double distanceKm(EstablishmentModel e) {
    final h = e.id.hashCode & 0x7fffffff;
    return 0.3 + (h % 95) / 10.0;
  }

  /// Estabelecimentos "próximos a você": o filtro/busca atual ordenado do mais
  /// próximo ao mais distante (ver [distanceKm]).
  List<EstablishmentModel> get nearby {
    final list = List<EstablishmentModel>.of(_filtered)
      ..sort((a, b) => distanceKm(a).compareTo(distanceKm(b)));
    return list.take(5).toList();
  }

  /// Procura na lista completa (não filtrada) o estabelecimento de [id].
  /// Usado para resolver a clínica de um veterinário ao agendar consulta.
  EstablishmentModel? establishmentById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final e in _all) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repository.getAll();
      _applyFilters();
    } catch (_) {
      _error = 'Não foi possível carregar os estabelecimentos.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadAvailableVets({String token = ''}) async {
    if (_availableVets.isNotEmpty) return;
    _loadingVets = true;
    notifyListeners();
    try {
      _availableVets = await VeterinarianService.fetchAvailable(token: token);
    } catch (_) {
      _availableVets = [];
    } finally {
      _loadingVets = false;
      notifyListeners();
    }
  }

  void filterByType(String? type) {
    _typeFilter = type ?? 'Todos';
    _applyFilters();
    notifyListeners();
  }

  void searchByName(String query) {
    _query = query.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Combina o filtro de categoria com o termo de busca sobre a lista
  /// completa, para que ambos sejam respeitados ao mesmo tempo.
  void _applyFilters() {
    Iterable<EstablishmentModel> result = _all;

    if (_typeFilter == 'Veterinário') {
      result = result.where((e) => e.isVeterinario);
    } else if (_typeFilter != 'Todos') {
      final term = _typeFilter.toLowerCase();
      result = result.where((e) =>
          e.name.toLowerCase().contains(term) ||
          e.services.any((s) => s.name.toLowerCase().contains(term)) ||
          e.services.any((s) => s.categoriaLabel.toLowerCase().contains(term)));
    }

    if (_query.isNotEmpty) {
      result = result.where((e) =>
          e.name.toLowerCase().contains(_query) ||
          e.services.any((s) => s.name.toLowerCase().contains(_query)));
    }

    _filtered = result.toList();
  }
}
