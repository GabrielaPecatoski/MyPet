import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/loja_provider.dart';
import '../widgets/mypet_app_bar.dart';
import 'product_detail_screen.dart';

class LojaScreen extends StatefulWidget {
  const LojaScreen({super.key});
  @override
  State<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends State<LojaScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MypetAppBar(
        showBack: false,
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Carrinho',
                icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.dark),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
              if (cart.count > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${cart.count}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            elevation: 0.5,
            shadowColor: Colors.black12,
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Produtos'),
                Tab(text: 'Pedidos'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _ProdutosTab(),
                _PedidosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProdutosTab extends StatefulWidget {
  const _ProdutosTab();
  @override
  State<_ProdutosTab> createState() => _ProdutosTabState();
}

class _ProdutosTabState extends State<_ProdutosTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LojaProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loja = context.watch<LojaProvider>();
    final cart = context.watch<CartProvider>();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Row(children: [
            const Icon(Icons.search, color: AppColors.grey),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar produtos...', hintStyle: TextStyle(color: AppColors.grey),
                border: InputBorder.none,
              ),
              onSubmitted: (v) => context.read<LojaProvider>().loadProducts(search: v),
              onChanged: (v) { if (v.isEmpty) context.read<LojaProvider>().loadProducts(); },
            )),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: AppColors.grey),
                onPressed: () { _searchCtrl.clear(); context.read<LojaProvider>().loadProducts(); },
              ),
          ]),
        ),
      ),
      Expanded(child: loja.isLoadingProducts
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : loja.products.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off, size: 48, color: AppColors.greyLight),
                  SizedBox(height: 8),
                  Text('Nenhum produto encontrado', style: TextStyle(color: AppColors.grey)),
                ]))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78,
                  ),
                  itemCount: loja.products.length,
                  itemBuilder: (ctx, i) {
                    final p = loja.products[i] as Map<String, dynamic>;
                    return _ProductCard(
                      product: p,
                      cartQty: cart.quantityOf(p['id'] as String),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ProductDetailScreen(),
                        settings: RouteSettings(arguments: ProductModel.fromJson(p)),
                      )),
                      onAdd: () {
                        context.read<CartProvider>().add(p);
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.clearSnackBars();
                        messenger.showSnackBar(SnackBar(
                          content: Text('${p['name']} adicionado!'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(milliseconds: 800),
                        ));
                      },
                    );
                  },
                )),
    ]);
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int cartQty;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const _ProductCard({required this.product, required this.cartQty, required this.onTap, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final price = (product['price'] as num).toDouble();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: product['imageUrl'] != null
                ? Image.network(product['imageUrl'] as String, fit: BoxFit.cover, width: double.infinity)
                : Container(color: AppColors.primaryLight,
                    child: const Center(child: Icon(Icons.pets, size: 40, color: AppColors.primary))),
          )),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name'] as String,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark)),
              const SizedBox(height: 2),
              Text(product['brand'] as String? ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('R\$ ${price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: cartQty > 0
                        ? Text('$cartQty',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                        : const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PedidosTab extends StatefulWidget {
  const _PedidosTab();
  @override
  State<_PedidosTab> createState() => _PedidosTabState();
}

class _PedidosTabState extends State<_PedidosTab> {
  int _filterIdx = 0;

  static const _filters = ['Histórico', 'Aguardando', 'Cancelados'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<LojaProvider>().loadOrders(auth.user?.id ?? '');
    });
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> orders) {
    if (_filterIdx == 1) {
      return orders.where((p) {
        final s = (p['status'] as String).toUpperCase();
        return s == 'PENDING' || s == 'PROCESSING';
      }).toList();
    }
    if (_filterIdx == 2) {
      return orders.where((p) {
        final s = (p['status'] as String).toUpperCase();
        return s == 'CANCELLED' || s == 'REJECTED' || s == 'REFUNDED';
      }).toList();
    }
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final loja = context.watch<LojaProvider>();
    final filtered = _filterOrders(loja.orders);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: List.generate(_filters.length, (i) => Padding(
          padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
          child: ChoiceChip(
            label: Text(_filters[i]),
            selected: _filterIdx == i,
            onSelected: (_) => setState(() => _filterIdx = i),
            selectedColor: AppColors.primaryLight,
            labelStyle: TextStyle(
              color: _filterIdx == i ? AppColors.primary : AppColors.grey,
              fontWeight: _filterIdx == i ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            side: BorderSide(color: _filterIdx == i ? AppColors.primary : AppColors.greyLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            showCheckmark: false,
          ),
        ))),
      ),

      Expanded(child: loja.isLoadingOrders
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : filtered.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    _filterIdx == 1 ? Icons.schedule : _filterIdx == 2 ? Icons.cancel_outlined : Icons.receipt_long_outlined,
                    size: 48, color: AppColors.greyLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterIdx == 1 ? 'Nenhum pedido aguardando' : _filterIdx == 2 ? 'Nenhum pedido cancelado' : 'Nenhum pedido encontrado',
                    style: const TextStyle(color: AppColors.grey),
                  ),
                ]))
              : RefreshIndicator(
                  onRefresh: () {
                    final auth = context.read<AuthProvider>();
                    return context.read<LojaProvider>().loadOrders(auth.user?.id ?? '');
                  },
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _PedidoCard(payment: filtered[i]),
                  ),
                )),
    ]);
  }
}

class _PedidoCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PedidoCard({required this.payment});

  static const _statusLabel = {
    'APPROVED': 'Aprovado',
    'PENDING': 'Aguardando',
    'PROCESSING': 'Processando',
    'REJECTED': 'Recusado',
    'CANCELLED': 'Cancelado',
    'REFUNDED': 'Estornado',
  };

  static const _statusColor = {
    'APPROVED': AppColors.success,
    'PENDING': AppColors.warning,
    'PROCESSING': AppColors.warning,
    'REJECTED': AppColors.danger,
    'CANCELLED': AppColors.danger,
    'REFUNDED': AppColors.grey,
  };

  static const _methodLabel = {
    'PIX': 'Pix',
    'CREDIT_CARD': 'Cartão de Crédito',
    'DEBIT_CARD': 'Cartão de Débito',
    'CASH': 'Dinheiro',
    'BOLETO': 'Boleto',
  };

  static const _methodIcon = {
    'PIX': Icons.qr_code_2,
    'CREDIT_CARD': Icons.credit_card,
    'DEBIT_CARD': Icons.credit_card_outlined,
    'CASH': Icons.money,
    'BOLETO': Icons.barcode_reader,
  };

  @override
  Widget build(BuildContext context) {
    final status = payment['status'] as String? ?? 'PENDING';
    final method = payment['method'] as String? ?? '';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = payment['createdAt'] as String? ?? '';
    final order = payment['order'] as Map<String, dynamic>?;
    final items = (order?['items'] as List<dynamic>?) ?? [];
    final installments = payment['installments'] as int? ?? 1;

    final date = createdAt.isNotEmpty ? _formatDate(createdAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: Icon(_methodIcon[method] ?? Icons.payment, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_methodLabel[method] ?? method,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
              if (date.isNotEmpty)
                Text(date, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
            ])),
            _StatusBadge(status: status, label: _statusLabel[status] ?? status, color: _statusColor[status] ?? AppColors.grey),
          ]),
        ),

        if (items.isNotEmpty) ...[
          const Divider(height: 1, color: AppColors.greyLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(children: items.take(3).map((item) {
              final it = item as Map<String, dynamic>;
              final product = it['product'] as Map<String, dynamic>?;
              final qty = it['quantity'] as int? ?? 1;
              final name = product?['name'] as String? ?? 'Produto';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.circle, size: 5, color: AppColors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${qty}x $name',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      overflow: TextOverflow.ellipsis)),
                ]),
              );
            }).toList()),
          ),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
              child: Text('+ ${items.length - 3} item(s)',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey)),
            ),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              installments > 1 ? '${installments}x de R\$ ${(amount / installments).toStringAsFixed(2)}' : '',
              style: const TextStyle(fontSize: 11, color: AppColors.grey),
            ),
            Text('Total: R\$ ${amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark)),
          ]),
        ),

        if (payment['boletoCode'] != null) ...[
          const Divider(height: 1, color: AppColors.greyLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(children: [
              Expanded(child: Text(payment['boletoCode'] as String,
                  style: const TextStyle(fontSize: 10, color: AppColors.grey),
                  overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
                child: const Icon(Icons.copy, size: 16, color: AppColors.primary),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  final Color color;
  const _StatusBadge({required this.status, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}
