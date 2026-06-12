import 'package:flutter/material.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/orders_repository.dart';

class LojaProvider extends ChangeNotifier {
  final ICatalogRepository _catalogRepo;
  final IOrdersRepository _ordersRepo;

  LojaProvider(this._catalogRepo, this._ordersRepo);

  List<dynamic> _products = [];
  List<Map<String, dynamic>> _orders = [];
  bool _loadingProducts = false;
  bool _loadingOrders = false;

  List<dynamic> get products => _products;
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoadingProducts => _loadingProducts;
  bool get isLoadingOrders => _loadingOrders;

  Future<void> loadProducts({String? search}) async {
    _loadingProducts = true;
    notifyListeners();
    try {
      _products = await _catalogRepo.getAll(search: search);
    } catch (_) {
      _products = [];
    }
    _loadingProducts = false;
    notifyListeners();
  }

  Future<void> loadOrders(String userId) async {
    _loadingOrders = true;
    notifyListeners();
    try {
      _orders = await _ordersRepo.getByUser(userId);
    } catch (_) {
      _orders = [];
    }
    _loadingOrders = false;
    notifyListeners();
  }

}
