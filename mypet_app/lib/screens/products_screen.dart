import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/store_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/mypet_app_bar.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MypetAppBar(
        showBack: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: AppColors.dark),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
              if (cart.count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                    constraints: const BoxConstraints(
                        minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.count}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Buscar produtos...',
                        hintStyle: TextStyle(color: AppColors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (v) => context.read<LojaProvider>().loadProducts(search: v),
                      onChanged: (v) {
                        if (v.isEmpty) context.read<LojaProvider>().loadProducts();
                      },
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear,
                          size: 18, color: AppColors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        context.read<LojaProvider>().loadProducts();
                      },
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: loja.isLoadingProducts
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : loja.products.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: AppColors.greyLight),
                            SizedBox(height: 8),
                            Text('Nenhum produto encontrado',
                                style:
                                    TextStyle(color: AppColors.grey)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: loja.products.length,
                        itemBuilder: (ctx, i) {
                          final p = loja.products[i] as Map<String, dynamic>;
                          return _ProductCard(
                            product: p,
                            cartQty: cart.quantityOf(p['id'] as String),
                            onTap: () => Navigator.pushNamed(
                              context, '/product-detail',
                              arguments: ProductModel.fromJson(p),
                            ),
                            onAdd: () {
                              context
                                  .read<CartProvider>()
                                  .add(p);
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
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  const _ProductCard(
      {required this.product,
      required this.cartQty,
      required this.onAdd,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: AppColors.primaryLight,
              child: AppImage(
                url: product['imageUrl'] as String?,
                fit: BoxFit.cover,
                fallback: const Center(
                  child: Icon(Icons.shopping_bag,
                      color: AppColors.primary, size: 40),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.dark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product['brand'] ?? '',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'R\$ ${(product['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary),
                      ),
                    ),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cartQty > 0
                              ? AppColors.success
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: cartQty > 0
                            ? Text(
                                '$cartQty',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              )
                            : const Icon(Icons.add,
                                color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
