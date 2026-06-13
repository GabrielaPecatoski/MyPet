import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/order_status.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_orders_provider.dart';
import '../providers/establishment_provider.dart';
import '../repositories/establishment_orders_repository.dart';
import '../widgets/order_progress_bar.dart';

class EstabPedidosView extends StatelessWidget {
  const EstabPedidosView({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          EstablishmentOrdersProvider(EstablishmentOrdersRepository()),
      child: const _EstabPedidosBody(),
    );
  }
}

class _EstabPedidosBody extends StatefulWidget {
  const _EstabPedidosBody();
  @override
  State<_EstabPedidosBody> createState() => _EstabPedidosBodyState();
}

class _EstabPedidosBodyState extends State<_EstabPedidosBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final estabProvider = context.read<EstablishmentProvider>();

    for (var i = 0; i < 20 && estabProvider.establishmentId == null && mounted; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (!mounted) return;
    final estabId = estabProvider.establishmentId;
    if (estabId == null || auth.token == null) return;
    await context
        .read<EstablishmentOrdersProvider>()
        .load(estabId: estabId, token: auth.token!);
  }

  Future<void> _advance(Map<String, dynamic> order) async {
    final ok =
        await context.read<EstablishmentOrdersProvider>().advance(order);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao atualizar pedido.'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  // abas por status; pedidos aguardando pagamento/cancelados não aparecem aqui
  static const _filters = ['Preparando', 'A caminho', 'Prontos', 'Entregues'];
  int _filterIdx = 0;

  bool _matches(int idx, Map<String, dynamic> o) {
    final status = o['status'] as String? ?? '';
    final pickup = (o['deliveryMethod'] as String? ?? 'PICKUP') == 'PICKUP';
    switch (idx) {
      case 0:
        return status == 'ENVIANDO';
      case 1:
        return status == 'A_CAMINHO' && !pickup;
      case 2:
        return status == 'A_CAMINHO' && pickup;
      case 3:
        return status == 'FINALIZADO';
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EstablishmentOrdersProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.estab));
    }
    final visible = provider.orders
        .where((o) => List.generate(_filters.length, (i) => i).any((i) => _matches(i, o)))
        .toList();
    if (visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.estab,
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
    final filtered = visible.where((o) => _matches(_filterIdx, o)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: List.generate(_filters.length, (i) {
              final count = visible.where((o) => _matches(i, o)).length;
              final sel = _filterIdx == i;
              return Padding(
                padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
                child: FilterChip(
                  label: Text(count > 0 ? '${_filters[i]} ($count)' : _filters[i]),
                  selected: sel,
                  onSelected: (_) => setState(() => _filterIdx = i),
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.estab.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: sel ? AppColors.estab : AppColors.grey,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(color: sel ? AppColors.estab : AppColors.greyLight),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1, color: AppColors.greyLight),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.estab,
            child: filtered.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text('Nenhum pedido em "${_filters[_filterIdx]}".',
                          style: const TextStyle(color: AppColors.grey)),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _EstabOrderCard(
                        order: filtered[i], onAdvance: () => _advance(filtered[i])),
                  ),
          ),
        ),
      ],
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
              child: Icon(pickup ? Icons.store_outlined : Icons.delivery_dining, color: AppColors.estab, size: 20),
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
                const Icon(Icons.arrow_forward, size: 16, color: AppColors.estab),
                const SizedBox(width: 6),
                Text(actionLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.estab)),
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
