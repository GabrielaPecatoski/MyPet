import 'package:flutter/material.dart';
import '../models/establishment.dart';
import '../repositories/establishment_list_repository.dart';

class HomeProvider extends ChangeNotifier {
  final IEstablishmentListRepository _repository;

  HomeProvider(this._repository);

  List<EstablishmentModel> _all = [];
  List<EstablishmentModel> _filtered = [];
  bool _loading = false;
  String? _error;

  List<EstablishmentModel> get establishments => _filtered;
  bool get isLoading => _loading;
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

  void filterByType(String? type) {
    if (type == null || type == 'Todos') {
      _filtered = List.of(_all);
    } else {
      final term = type.toLowerCase();
      _filtered = _all
          .where((e) =>
              e.name.toLowerCase().contains(term) ||
              e.services.any((s) => s.name.toLowerCase().contains(term)))
          .toList();
    }
    notifyListeners();
  }
}
