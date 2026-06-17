import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/establishment_products_repository.dart';

class EstablishmentProductsProvider extends ChangeNotifier {
  final IEstablishmentProductsRepository _repository;

  EstablishmentProductsProvider(this._repository);

  final List<ProductModel> _products = [];
  bool _loading = true;
  String? _estabId;
  String? _token;
  String _filter = 'Todos';
  String _searchQuery = '';

  bool get isLoading => _loading;
  String? get estabId => _estabId;
  String get filter => _filter;
  String get searchQuery => _searchQuery;
  int get totalProducts => _products.length;
  int get totalAtivos => _products.where((p) => p.active).length;
  double get receitaTotal =>
      _products.fold(0.0, (s, p) => s + p.price * p.stock);

  List<ProductModel> get filtered {
    var list = _products.where((p) {
      if (_filter == 'Ativos') return p.active;
      if (_filter == 'Inativos') return !p.active;
      if (_filter == 'Sem estoque') return p.stock == 0;
      return true;
    }).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  void setSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> load(String? ownerId, {String? token}) async {
    _token = token;
    if (ownerId == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _estabId = await _repository.ownerEstablishmentId(ownerId, token: token);
      if (_estabId == null) {
        _loading = false;
        notifyListeners();
        return;
      }
      await _reloadProducts();
    } catch (_) {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadProducts() async {
    if (_estabId == null) return;
    _loading = true;
    notifyListeners();
    try {
      final list = await _repository.fetchProducts(_estabId!, token: _token);
      _products
        ..clear()
        ..addAll(list);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> fields) async {
    if (_estabId == null) return false;
    try {
      await _repository
          .create({'establishmentId': _estabId, ...fields}, token: _token);
      await _reloadProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(String productId, Map<String, dynamic> fields) async {
    try {
      await _repository.update(productId, fields, token: _token);
      await _reloadProducts();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleActive(ProductModel product) async {
    try {
      await _repository.setActive(product.id, !product.active, token: _token);
      await _reloadProducts();
    } catch (_) {}
  }

  Future<void> delete(String productId) async {
    try {
      await _repository.delete(productId, token: _token);
      await _reloadProducts();
    } catch (_) {}
  }
}
