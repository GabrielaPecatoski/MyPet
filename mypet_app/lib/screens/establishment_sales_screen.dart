import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/establishment_provider.dart';
import '../providers/establishment_sales_provider.dart';
import '../repositories/establishment_sales_repository.dart';
import '../widgets/mypet_app_bar.dart';

class EstabVendasScreen extends StatelessWidget {
  const EstabVendasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          EstablishmentSalesProvider(EstablishmentSalesRepository()),
      child: const _EstabVendasView(),
    );
  }
}

class _EstabVendasView extends StatefulWidget {
  const _EstabVendasView();
  @override
  State<_EstabVendasView> createState() => _EstabVendasViewState();
}

class _EstabVendasViewState extends State<_EstabVendasView> {
  static const _filters = ['Todos', 'Retirada', 'Entrega'];

  static const _deliveryLabels = {
    'PENDING':   'Aguardando',
    'PREPARING': 'Preparando',
    'READY':     'Pronto',
    'DELIVERED': 'Entregue',
  };

  static const _deliveryColors = {
    'PENDING':   AppColors.warning,
    'PREPARING': Color(0xFF6366F1),
    'READY':     AppColors.estab,
    'DELIVERED': AppColors.success,
  };

  static const _deliverySteps = ['PENDING', 'PREPARING', 'READY', 'DELIVERED'];

  static const _actionLabels = {
    'PENDING':   'Confirmar Pedido',
    'PREPARING': 'Marcar como Pronto',
    'READY':     'Confirmar Entrega',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final estabId = context.read<EstablishmentProvider>().establishmentId;
    final ok = await context.read<EstablishmentSalesProvider>().load(estabId);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar pedidos.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _advanceDelivery(Map<String, dynamic> order) async {
    final ok =
        await context.read<EstablishmentSalesProvider>().advanceDelivery(order);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar pedido.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EstablishmentSalesProvider>();
    final filtered = provider.filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: Column(children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: List.generate(_filters.length, (i) => Padding(
            padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
            child: ChoiceChip(
              label: Text(_filters[i]),
              selected: provider.filterIdx == i,
              onSelected: (_) => provider.setFilter(i),
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: provider.filterIdx == i ? AppColors.estab : AppColors.grey,
                fontWeight:
                    provider.filterIdx == i ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                  color:
                      provider.filterIdx == i ? AppColors.estab : AppColors.greyLight),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              showCheckmark: false,
            ),
          ))),
        ),

        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.estab))
              : filtered.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.greyLight),
                        SizedBox(height: 12),
                        Text('Nenhuma venda encontrada.',
                            style: TextStyle(color: AppColors.grey, fontSize: 14)),
                      ],
                    ))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.estab,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _OrderCard(
                          order: filtered[i],
                          deliveryLabels: _deliveryLabels,
                          deliveryColors: _deliveryColors,
                          deliverySteps: _deliverySteps,
                          actionLabels: _actionLabels,
                          onAdvance: () => _advanceDelivery(filtered[i]),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Map<String, String> deliveryLabels;
  final Map<String, Color> deliveryColors;
  final List<String> deliverySteps;
  final Map<String, String> actionLabels;
  final VoidCallback onAdvance;

  const _OrderCard({
    required this.order,
    required this.deliveryLabels,
    required this.deliveryColors,
    required this.deliverySteps,
    required this.actionLabels,
    required this.onAdvance,
  });

  Map<String, dynamic>? get _payment {
    final payments = order['payments'] as List?;
    if (payments == null || payments.isEmpty) return null;
    return payments.first as Map<String, dynamic>;
  }

  bool get _isPaymentPending {
    final orderStatus = order['status'] as String? ?? '';
    return orderStatus == 'AWAITING_PAYMENT';
  }

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final deliveryStatus = order['deliveryStatus'] as String? ?? 'PENDING';
    final isDelivered = deliveryStatus == 'DELIVERED';
    final statusIdx = deliverySteps.indexOf(deliveryStatus);
    final isLast = statusIdx >= deliverySteps.length - 1;

    final payment = _payment;
    final isDelivery =
        (payment?['deliveryMethod'] as String? ?? 'PICKUP') == 'DELIVERY';
    final address = payment?['deliveryAddress'] as String?;
    final createdAt = order['createdAt'] as String? ?? '';
    final dateStr = createdAt.isNotEmpty ? _fmt(createdAt) : '';

    final statusColor = deliveryColors[deliveryStatus] ?? AppColors.grey;
    final statusLabel = deliveryLabels[deliveryStatus] ?? deliveryStatus;
    final actionLabel = actionLabels[deliveryStatus] ?? 'Avançar';

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
              decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(
                isDelivery ? Icons.delivery_dining : Icons.store_outlined,
                color: AppColors.estab, size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isDelivery ? 'Entrega' : 'Retirada no local',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
              ),
              if (dateStr.isNotEmpty)
                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _StatusBadge(label: statusLabel, color: statusColor),
              if (_isPaymentPending) ...[
                const SizedBox(height: 4),
                _StatusBadge(label: 'Pgto. pendente', color: AppColors.warning),
              ],
            ]),
          ]),
        ),

        if (isDelivery && address != null && address.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(address,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ],

        const Divider(height: 1, color: AppColors.greyLight),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(children: items.map((item) {
            final product = item['product'] as Map<String, dynamic>?;
            final qty = item['quantity'] as int? ?? 1;
            final name = product?['name'] as String? ?? 'Produto';
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.circle, size: 5, color: AppColors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${qty}x $name',
                      style: const TextStyle(fontSize: 13, color: AppColors.dark)),
                ),
                Text('R\$ ${(price * qty).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.grey)),
              ]),
            );
          }).toList()),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('Total: R\$ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: _ProgressBar(
            steps: deliverySteps,
            labels: deliveryLabels,
            current: deliveryStatus,
            colors: deliveryColors,
          ),
        ),

        if (!isLast) ...[
          const Divider(height: 1, color: AppColors.greyLight),
          InkWell(
            onTap: onAdvance,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: deliveryStatus == 'PENDING'
                    ? AppColors.estab.withValues(alpha: 0.07)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      deliveryStatus == 'PENDING'
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_ios,
                      size: deliveryStatus == 'PENDING' ? 18 : 13,
                      color: AppColors.estab,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.estab,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        if (isDelivered)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: const Center(
              child: Text('Pedido concluído',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
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

class _ProgressBar extends StatelessWidget {
  final List<String> steps;
  final Map<String, String> labels;
  final String current;
  final Map<String, Color> colors;

  const _ProgressBar({
    required this.steps,
    required this.labels,
    required this.current,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final currentIdx = steps.indexOf(current);
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= currentIdx;
        final color = done ? (colors[steps[i]] ?? AppColors.estab) : AppColors.greyLight;
        return Expanded(
          child: Column(children: [
            Row(children: [
              if (i > 0)
                Expanded(child: Container(height: 2, color: i <= currentIdx ? AppColors.estab : AppColors.greyLight)),
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (i < steps.length - 1)
                Expanded(child: Container(height: 2, color: i < currentIdx ? AppColors.estab : AppColors.greyLight)),
            ]),
            const SizedBox(height: 4),
            Text(
              labels[steps[i]] ?? '',
              style: TextStyle(
                fontSize: 9,
                color: done ? color : AppColors.greyLight,
                fontWeight: i == currentIdx ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ]),
        );
      }),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}
