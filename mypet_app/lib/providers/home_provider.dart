import 'package:flutter/material.dart';
import '../core/geo.dart';
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
  String _typeFilter = 'Todos';
  String _query = '';
  double? _originLat;
  double? _originLng;

  List<EstablishmentModel> get establishments => _filtered;
  List<VeterinarianModel> get availableVets => _availableVets;
  bool get isLoading => _loading;
  bool get loadingVets => _loadingVets;
  String? get error => _error;
  String get query => _query;
  bool get hasOrigin => _originLat != null && _originLng != null;

  /// Define a origem (endereço do cliente) para ordenar/medir por distância.
  void setOrigin(double? lat, double? lng) {
    if (_originLat == lat && _originLng == lng) return;
    _originLat = lat;
    _originLng = lng;
    _recompute();
    _sortVetsByDistance();
    notifyListeners();
  }

  /// Distância em km de [e] até a origem, ou null se faltar alguma coordenada.
  double? distanceKm(EstablishmentModel e) {
    if (_originLat == null || _originLng == null || e.lat == null || e.lng == null) {
      return null;
    }
    return haversineKm(_originLat!, _originLng!, e.lat!, e.lng!);
  }

  /// Distância em km de um veterinário até a origem, ou null.
  double? vetDistanceKm(VeterinarianModel v) {
    if (_originLat == null || _originLng == null || v.lat == null || v.lng == null) {
      return null;
    }
    return haversineKm(_originLat!, _originLng!, v.lat!, v.lng!);
  }

  void _sortVetsByDistance() {
    if (!hasOrigin) return;
    _availableVets.sort((a, b) {
      final da = vetDistanceKm(a);
      final db = vetDistanceKm(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repository.getAll();
      _recompute();
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
      _sortVetsByDistance();
    } catch (_) {
      _availableVets = [];
    } finally {
      _loadingVets = false;
      notifyListeners();
    }
  }

  void filterByType(String? type) {
    _typeFilter = (type == null || type.isEmpty) ? 'Todos' : type;
    _recompute();
    notifyListeners();
  }

  void search(String query) {
    _query = query.trim().toLowerCase();
    _recompute();
    notifyListeners();
  }

  void _recompute() {
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
          e.address.toLowerCase().contains(_query) ||
          e.typeLabel.toLowerCase().contains(_query) ||
          e.services.any((s) => s.name.toLowerCase().contains(_query)) ||
          e.services.any((s) => s.categoriaLabel.toLowerCase().contains(_query)));
    }

    final list = result.toList();
    if (hasOrigin) {
      list.sort((a, b) {
        final da = distanceKm(a);
        final db = distanceKm(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }
    _filtered = list;
  }
}
