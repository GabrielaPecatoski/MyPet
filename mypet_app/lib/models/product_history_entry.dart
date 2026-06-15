/// Uma ocorrência de um produto dentro de um pedido — base do histórico de
/// vendas (visão da loja) e do histórico de compras do produto (visão do
/// cliente). Derivada dos `orders` existentes, sem persistência própria.
class ProductHistoryEntry {
  final String orderId;
  final DateTime? date;
  final int quantity;
  final double unitPrice;
  final String status;

  ProductHistoryEntry({
    required this.orderId,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.status,
  });

  double get subtotal => unitPrice * quantity;

  /// Constrói (ou não) uma entrada a partir de um pedido e de um item dele,
  /// quando o item for do produto informado. Retorna `null` caso contrário.
  static ProductHistoryEntry? fromOrderItem(
    Map<String, dynamic> order,
    Map item,
    String productId,
  ) {
    if (item['productId'] != productId) return null;
    return ProductHistoryEntry(
      orderId: order['id'] as String? ?? '',
      date: DateTime.tryParse(order['createdAt'] as String? ?? '')?.toLocal(),
      quantity: (item['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (item['price'] as num?)?.toDouble() ?? 0,
      status: order['status'] as String? ?? '',
    );
  }
}
