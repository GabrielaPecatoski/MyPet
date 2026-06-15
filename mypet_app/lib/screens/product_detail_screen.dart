import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/product.dart';
import '../models/product_history_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_history_provider.dart';
import '../repositories/orders_repository.dart';
import '../widgets/app_image.dart';
import '../widgets/mypet_app_bar.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as ProductModel;
    final auth = context.read<AuthProvider>();
    return ChangeNotifierProvider(
      create: (_) => ProductHistoryProvider(OrdersRepository())
        ..loadForCustomer(
          productId: product.id,
          userId: auth.user?.id,
          token: auth.token,
        ),
      child: _ProductDetailView(product: product),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  final ProductModel product;
  const _ProductDetailView({required this.product});

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  int _qty = 1;

  void _rebuy(int qty) {
    final product = widget.product;
    context.read<CartProvider>().addQty({
      'id': product.id,
      'name': product.name,
      'brand': product.brand,
      'price': product.price,
      'unit': product.unit,
    }, qty);
    final nav = Navigator.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '$qty ${qty == 1 ? 'unidade adicionada' : 'unidades adicionadas'} ao carrinho'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1200),
      action: SnackBarAction(
        label: 'Ver carrinho',
        textColor: Colors.white,
        onPressed: () => nav.pushNamed('/cart'),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cart = context.watch<CartProvider>();
    final cartQty = cart.quantityOf(product.id);
    final inStock = product.stock > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImage(imageUrl: product.imageUrl),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoCard(
                          children: [
                            _InfoRow(
                              icon: Icons.category_outlined,
                              label: 'Categoria',
                              value: product.category.isEmpty
                                  ? 'Sem categoria'
                                  : product.category,
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(
                              icon: Icons.inventory_2_outlined,
                              label: 'Disponibilidade',
                              value: inStock ? 'Em estoque' : 'Sem estoque',
                              valueColor: inStock
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoCard(
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark),
                            ),
                            if (product.brand.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.greyLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  product.brand,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.grey),
                                ),
                              ),
                            ],
                            if (product.description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                product.description,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.grey,
                                    height: 1.5),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'R\$ ${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    const Text('Estoque',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey)),
                                    Text(
                                      '${product.stock} ${product.unit}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.dark),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (cartQty > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: AppColors.success, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '$cartQty ${cartQty == 1 ? 'unidade' : 'unidades'} no carrinho',
                                  style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _PurchaseHistorySection(
                          unit: product.unit,
                          enabled: inStock,
                          onRebuy: _rebuy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (inStock)
            _AddToCartBar(
              qty: _qty,
              onDecrement: () {
                if (_qty > 1) setState(() => _qty--);
              },
              onIncrement: () => setState(() => _qty++),
              onAdd: () {
                context.read<CartProvider>().addQty({
                  'id': product.id,
                  'name': product.name,
                  'brand': product.brand,
                  'price': product.price,
                  'unit': product.unit,
                }, _qty);
                final nav = Navigator.of(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '$_qty ${_qty == 1 ? 'unidade adicionada' : 'unidades adicionadas'} ao carrinho'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(milliseconds: 1200),
                  action: SnackBarAction(
                    label: 'Ver carrinho',
                    textColor: Colors.white,
                    onPressed: () => nav.pushNamed('/cart'),
                  ),
                ));
                setState(() => _qty = 1);
              },
            ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      color: AppColors.primaryLight,
      child: AppImage(
        url: imageUrl,
        fit: BoxFit.cover,
        fallback: const Center(
          child: Icon(Icons.shopping_bag, color: AppColors.primary, size: 72),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: 6),
        Text('$label: ',
            style:
                const TextStyle(fontSize: 13, color: AppColors.grey)),
        Text(
          value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.dark),
        ),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAdd;

  const _AddToCartBar({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: Row(
              children: [
                _QtyBtn(icon: Icons.remove, onTap: onDecrement),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _QtyBtn(
                    icon: Icons.add, onTap: onIncrement, filled: true),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Adicionar ao Carrinho',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QtyBtn(
      {required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final label = icon == Icons.remove ? 'Diminuir quantidade' : 'Aumentar quantidade';
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 18, color: filled ? Colors.white : AppColors.dark),
        ),
      ),
    );
  }
}

class _PurchaseHistorySection extends StatelessWidget {
  final String unit;
  final bool enabled;
  final void Function(int qty) onRebuy;

  const _PurchaseHistorySection({
    required this.unit,
    required this.enabled,
    required this.onRebuy,
  });

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ProductHistoryProvider>();
    // Some-se quando ainda carrega ou quando o cliente nunca comprou.
    if (history.isLoading || history.isEmpty) return const SizedBox.shrink();
    final entries = history.entries;

    return _InfoCard(
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            const Expanded(
              child: Text('Você já comprou este produto',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${history.totalQuantity} ${history.totalQuantity == 1 ? 'unidade comprada' : 'unidades compradas'} em ${history.orderCount} ${history.orderCount == 1 ? 'pedido' : 'pedidos'}',
          style: const TextStyle(fontSize: 12, color: AppColors.grey),
        ),
        const SizedBox(height: 12),
        ...entries.map((e) => _HistoryRow(entry: e, unit: unit)),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: enabled ? () => onRebuy(entries.first.quantity) : null,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Comprar novamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ProductHistoryEntry entry;
  final String unit;
  const _HistoryRow({required this.entry, required this.unit});

  @override
  Widget build(BuildContext context) {
    final d = entry.date;
    final dateStr = d == null
        ? 'Data indisponível'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 15, color: AppColors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(dateStr,
                style: const TextStyle(fontSize: 13, color: AppColors.dark)),
          ),
          Text(
            '${entry.quantity} $unit · R\$ ${entry.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
