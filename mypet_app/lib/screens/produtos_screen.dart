import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/mypet_app_bar.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  List<dynamic> _products = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({String? search}) async {
    setState(() => _loading = true);
    try {
      final path = search != null && search.isNotEmpty
          ? '${ApiConstants.productsEndpoint}?search=$search'
          : ApiConstants.productsEndpoint;
      final data = await ApiService.get(path);
      setState(() {
        _products = data as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _products = [
          {'id': 'prod-001', 'name': 'Areia Sanitária Gatos', 'brand': 'PetLove', 'price': 32.90, 'unit': '4kg'},
          {'id': 'prod-002', 'name': 'Areia Sanitária Gatos', 'brand': 'PetLove', 'price': 28.90, 'unit': '3kg'},
          {'id': 'prod-003', 'name': 'Ração Premium Cães', 'brand': 'Royal Canin', 'price': 89.90, 'unit': '3kg'},
          {'id': 'prod-004', 'name': 'Shampoo Pet', 'brand': 'PetShop Brasil', 'price': 24.90, 'unit': '500ml'},
          {'id': 'prod-005', 'name': 'Coleira Anti-Pulga', 'brand': 'Seresto', 'price': 45.00, 'unit': 'Un'},
          {'id': 'prod-006', 'name': 'Brinquedo Corda', 'brand': 'PetFun', 'price': 19.90, 'unit': 'Un'},
          {'id': 'prod-007', 'name': 'Ração Gatos Sênior', 'brand': 'Purina', 'price': 75.00, 'unit': '2kg'},
          {'id': 'prod-008', 'name': 'Comedouro Inox', 'brand': 'PetLife', 'price': 35.00, 'unit': 'Un'},
        ];
        _loading = false;
      });
    }
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
                      onSubmitted: (v) => _loadProducts(search: v),
                      onChanged: (v) {
                        if (v.isEmpty) _loadProducts();
                      },
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear,
                          size: 18, color: AppColors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        _loadProducts();
                      },
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _products.isEmpty
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
                        itemCount: _products.length,
                        itemBuilder: (ctx, i) {
                          final p = _products[i];
                          return _ProductCard(
                            product: p,
                            cartQty: cart.quantityOf(p['id'] as String),
                            onAdd: () {
                              context
                                  .read<CartProvider>()
                                  .add(p as Map<String, dynamic>);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content:
                                    Text('${p['name']} adicionado!'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 1),
                                action: SnackBarAction(
                                  label: 'Carrinho',
                                  textColor: Colors.white,
                                  onPressed: () => Navigator.pushNamed(
                                      context, '/cart'),
                                ),
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

  const _ProductCard(
      {required this.product,
      required this.cartQty,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            height: 100,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Icon(Icons.shopping_bag,
                  color: AppColors.primary, size: 40),
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
    );
  }
}
