import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/order_status.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/order_service.dart';
import '../widgets/order_progress_bar.dart';

class EstabPedidosView extends StatefulWidget {
  const EstabPedidosView({super.key});
  @override
  State<EstabPedidosView> createState() => _EstabPedidosViewState();
}

class _EstabPedidosViewState extends State<EstabPedidosView> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final estabProvider = context.read<EstablishmentProvider>();
    _token = auth.token;

    for (var i = 0; i < 20 && estabProvider.establishmentId == null && mounted; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    final estabId = estabProvider.establishmentId;
    if (estabId == null || _token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final data = await OrderService.fetchEstabOrders(token: _token!, establishmentId: estabId);
      if (mounted) setState(() => _orders = data);
    } catch (_) {
      if (mounted) setState(() => _orders = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advance(Map<String, dynamic> order) async {
    if (_token == null) return;
    try {
      await OrderService.advance(token: _token!, orderId: order['id'] as String);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar pedido: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(children: const [
          SizedBox(height: 80),
          Center(child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.greyLight),
            SizedBox(height: 12),
            Text('Nenhum pedido ainda.', style: TextStyle(color: AppColors.grey)),
          ])),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _EstabOrderCard(order: _orders[i], onAdvance: () => _advance(_orders[i])),
      ),
    );
  }
}

class _EstabOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAdvance;
  const _EstabOrderCard({required this.order, required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'AGUARDANDO_PAGAMENTO';
    final pickup = (order['deliveryMethod'] as String? ?? 'PICKUP') == 'PICKUP';
    final address = order['deliveryAddress'] as String?;
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final items = (order['items'] as List? ?? []);
    final qty = items.fold<int>(0, (s, it) => s + ((it as Map)['quantity'] as int? ?? 0));
    final createdAt = order['createdAt'] as String? ?? '';
    final actionLabel = OrderTracking.nextActionLabel(status, pickup: pickup);
    final waitingPayment = status == 'AGUARDANDO_PAGAMENTO';
    final cancelled = OrderTracking.isCancelled(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: Icon(pickup ? Icons.store_outlined : Icons.delivery_dining, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pickup ? 'Retirada no local' : 'Entrega',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
              if (createdAt.isNotEmpty)
                Text(_fmt(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.grey)),
            ])),
            _Badge(OrderTracking.label(status, pickup: pickup), OrderTracking.color(status)),
          ]),
        ),

        if (!pickup && address != null && address.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(address,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ),

        const Divider(height: 1, color: AppColors.greyLight),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$qty item(s)', style: const TextStyle(fontSize: 13, color: AppColors.grey)),
            Text('Total: R\$ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
          ]),
        ),

        if (!cancelled)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: OrderProgressBar(status: status, pickup: pickup),
          ),

        if (waitingPayment)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: const Center(child: Text('Aguardando pagamento do cliente',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning))),
          )
        else if (actionLabel != null) ...[
          const Divider(height: 1, color: AppColors.greyLight),
          InkWell(
            onTap: onAdvance,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(actionLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ])),
            ),
          ),
        ] else if (status == 'FINALIZADO')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: const Center(child: Text('Pedido finalizado',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success))),
          ),
      ]),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}
