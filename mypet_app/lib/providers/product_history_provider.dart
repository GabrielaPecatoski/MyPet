import 'package:flutter/material.dart';
import '../models/product_history_entry.dart';
import '../repositories/orders_repository.dart';

/// ViewModel do histórico de um produto:
/// - visão da loja: histórico de vendas do produto (todos os clientes);
/// - visão do cliente: minhas compras daquele produto.
///
/// Em ambos os casos parte dos pedidos já existentes e filtra os itens pelo
/// produto. Considera apenas vendas concretizadas (pedidos pagos), ignorando os
/// que aguardam pagamento ou foram cancelados.
class ProductHistoryProvider extends ChangeNotifier {
  final IOrdersRepository _ordersRepo;

  ProductHistoryProvider(this._ordersRepo);

  // status que representam uma venda de fato (já paga)
  static const _saleStatuses = {'ENVIANDO', 'A_CAMINHO', 'FINALIZADO'};

  List<ProductHistoryEntry> _entries = [];
  bool _loading = true;

  List<ProductHistoryEntry> get entries => _entries;
  bool get isLoading => _loading;
  bool get isEmpty => _entries.isEmpty;

  int get totalQuantity => _entries.fold(0, (s, e) => s + e.quantity);
  double get totalValue => _entries.fold(0.0, (s, e) => s + e.subtotal);
  int get orderCount => _entries.length;

  Future<void> loadForCustomer({
    required String productId,
    String? userId,
    String? token,
  }) =>
      _load(
        productId,
        () => userId == null
            ? Future.value(<Map<String, dynamic>>[])
            : _ordersRepo.getByUser(userId, token: token),
      );

  Future<void> loadForStore({
    required String productId,
    required String establishmentId,
    String? token,
  }) =>
      _load(
        productId,
        () => _ordersRepo.getByEstablishment(establishmentId, token: token),
      );

  Future<void> _load(
    String productId,
    Future<List<Map<String, dynamic>>> Function() fetch,
  ) async {
    _loading = true;
    notifyListeners();
    try {
      final orders = await fetch();
      final entries = <ProductHistoryEntry>[];
      for (final order in orders) {
        final status = order['status'] as String? ?? '';
        if (!_saleStatuses.contains(status)) continue;
        for (final item in (order['items'] as List? ?? [])) {
          final entry = ProductHistoryEntry.fromOrderItem(
              order, item as Map, productId);
          if (entry != null) entries.add(entry);
        }
      }
      entries.sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
      _entries = entries;
    } catch (_) {
      _entries = [];
    }
    _loading = false;
    notifyListeners();
  }
}
