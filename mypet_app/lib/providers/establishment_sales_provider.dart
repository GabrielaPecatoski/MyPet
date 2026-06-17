import 'package:flutter/material.dart';
import '../repositories/establishment_sales_repository.dart';

class EstablishmentSalesProvider extends ChangeNotifier {
  final IEstablishmentSalesRepository _repository;

  EstablishmentSalesProvider(this._repository);

  static const _deliverySteps = ['PENDING', 'PREPARING', 'READY', 'DELIVERED'];

  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;
  int _filterIdx = 0;
  String? _estabId;

  bool get isLoading => _loading;
  int get filterIdx => _filterIdx;

  void setFilter(int idx) {
    _filterIdx = idx;
    notifyListeners();
  }

  List<Map<String, dynamic>> get filtered {
    if (_filterIdx == 1) {
      return _orders
          .where((o) => _deliveryMethod(o) == 'PICKUP')
          .toList();
    }
    if (_filterIdx == 2) {
      return _orders
          .where((o) => _deliveryMethod(o) == 'DELIVERY')
          .toList();
    }
    return _orders;
  }

  String _deliveryMethod(Map<String, dynamic> order) {
    final payments = order['payments'] as List?;
    if (payments == null || payments.isEmpty) return 'PICKUP';
    final p = payments.first as Map<String, dynamic>;
    return p['deliveryMethod'] as String? ?? 'PICKUP';
  }

  Future<bool> load(String? estabId) async {
    _estabId = estabId;
    if (estabId == null) return true;
    _loading = true;
    notifyListeners();
    try {
      _orders = await _repository.fetchOrders(estabId);
      return true;
    } catch (_) {
      _orders = [];
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> advanceDelivery(Map<String, dynamic> order) async {
    final current = order['deliveryStatus'] as String? ?? 'PENDING';
    final idx = _deliverySteps.indexOf(current);
    if (idx >= _deliverySteps.length - 1) return true;
    final next = _deliverySteps[idx + 1];
    try {
      await _repository.updateDeliveryStatus(order['id'] as String, next);
      await load(_estabId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
