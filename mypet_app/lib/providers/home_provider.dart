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
  String _typeFilter = 'Todos';
  String _query = '';

  List<EstablishmentModel> get establishments => _filtered;
  List<VeterinarianModel> get availableVets => _availableVets;
  bool get isLoading => _loading;
  bool get loadingVets => _loadingVets;
  String? get error => _error;
  String get query => _query;

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

    _filtered = result.toList();
  }
}
