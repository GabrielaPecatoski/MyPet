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

  List<EstablishmentModel> get establishments => _filtered;
  List<VeterinarianModel> get availableVets => _availableVets;
  bool get isLoading => _loading;
  bool get loadingVets => _loadingVets;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repository.getAll();
      _filtered = List.of(_all);
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
    if (type == null || type == 'Todos') {
      _filtered = List.of(_all);
    } else if (type == 'Veterinário') {
      _filtered = _all.where((e) => e.isVeterinario).toList();
    } else {
      final term = type.toLowerCase();
      _filtered = _all
          .where((e) =>
              e.name.toLowerCase().contains(term) ||
              e.services.any((s) => s.name.toLowerCase().contains(term)) ||
              e.services.any((s) => s.categoriaLabel.toLowerCase().contains(term)))
          .toList();
    }
    notifyListeners();
  }
}
