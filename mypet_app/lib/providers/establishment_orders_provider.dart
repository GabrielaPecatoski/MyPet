import 'package:flutter/material.dart';
import '../repositories/establishment_orders_repository.dart';

class EstablishmentOrdersProvider extends ChangeNotifier {
  final IEstablishmentOrdersRepository _repository;

  EstablishmentOrdersProvider(this._repository);

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _estabId;
  String? _token;

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _loading;

  Future<void> load({required String estabId, required String token}) async {
    _estabId = estabId;
    _token = token;
    _loading = true;
    notifyListeners();
    try {
      _orders =
          await _repository.fetchOrders(estabId: estabId, token: token);
    } catch (_) {
      _orders = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> advance(Map<String, dynamic> order) async {
    if (_token == null || _estabId == null) return false;
    try {
      await _repository.advance(
          orderId: order['id'] as String, token: _token!);
      await load(estabId: _estabId!, token: _token!);
      return true;
    } catch (_) {
      return false;
    }
  }
}
