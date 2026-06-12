import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/mypet_app_bar.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as ProductModel;
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
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.shopping_bag,
                    color: AppColors.primary, size: 72),
              ),
            )
          : const Center(
              child: Icon(Icons.shopping_bag,
                  color: AppColors.primary, size: 72),
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
    return GestureDetector(
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
    );
  }
}
