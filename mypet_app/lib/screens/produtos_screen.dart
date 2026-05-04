import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/mypet_app_bar.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  List<dynamic> _products = [];
  List<Map<String, dynamic>> _cartItems = [];
  bool _loading = true;
  bool _hasError = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProducts(), _loadCart()]);
  }

  Future<void> _loadProducts({String? search}) async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final path = search != null && search.isNotEmpty
          ? '${ApiConstants.productsEndpoint}?search=${Uri.encodeComponent(search)}'
          : ApiConstants.productsEndpoint;
      final data = await ApiService.get(path);
      if (mounted) {
        setState(() {
          _products = data as List<dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _products = [];
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadCart() async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) return;
    try {
      final data = await ApiService.get(
        '${ApiConstants.cartEndpoint}/$userId',
        token: token,
      );
      if (mounted) {
        setState(() {
          _cartItems = (data as List<dynamic>)
              .map((c) => c as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _addToCart(dynamic product) async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) return;
    try {
      await ApiService.post(
        '${ApiConstants.cartEndpoint}/$userId',
        {'productId': product['id'] as String, 'quantity': 1},
        token: token,
      );
      await _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['name']} adicionado ao carrinho!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
            action: SnackBarAction(
              label: 'Ver Carrinho',
              textColor: Colors.white,
              onPressed: _showCart,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _removeFromCart(String productId) async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) return;
    try {
      await ApiService.delete(
        '${ApiConstants.cartEndpoint}/$userId/$productId',
        token: token,
      );
      await _loadCart();
    } catch (_) {}
  }

  Future<void> _updateCartQty(String productId, int qty) async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) return;
    if (qty <= 0) {
      await _removeFromCart(productId);
      return;
    }
    try {
      await ApiService.patch(
        '${ApiConstants.cartEndpoint}/$userId/$productId',
        {'quantity': qty},
        token: token,
      );
      await _loadCart();
    } catch (_) {}
  }

  Future<void> _clearCart() async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) return;
    try {
      await ApiService.delete(
        '${ApiConstants.cartEndpoint}/$userId',
        token: token,
      );
      await _loadCart();
    } catch (_) {}
  }

  int _cartQtyFor(String productId) {
    try {
      final item = _cartItems.firstWhere(
        (c) => (c['productId'] as String?) == productId ||
            ((c['product'] as Map<String, dynamic>?)?['id'] as String?) ==
                productId,
      );
      return (item['quantity'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  int get _totalCartItems =>
      _cartItems.fold(0, (s, c) => s + (c['quantity'] as num).toInt());

  Future<void> _checkout(String userId) async {
    final token = context.read<AuthProvider>().token;
    try {
      await ApiService.post('${ApiConstants.ordersEndpoint}/$userId', {},
          token: token);
      await _loadCart();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido realizado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('vazio')
                  ? 'Carrinho vazio'
                  : 'Erro ao finalizar pedido. Tente novamente.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showCart() {
    final userId = context.read<AuthProvider>().user?.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          double total = 0;
          for (final item in _cartItems) {
            final product = item['product'] as Map<String, dynamic>?;
            final price = product != null
                ? (product['price'] as num).toDouble()
                : 0.0;
            total += price * (item['quantity'] as num).toInt();
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.shopping_cart,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Meu Carrinho',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark)),
                    const Spacer(),
                    if (_cartItems.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          await _clearCart();
                          setModalState(() {});
                        },
                        child: const Text('Limpar',
                            style: TextStyle(color: AppColors.danger)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_cartItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 48, color: AppColors.greyLight),
                        SizedBox(height: 8),
                        Text('Carrinho vazio',
                            style: TextStyle(color: AppColors.grey)),
                      ],
                    ),
                  )
                else ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(ctx).size.height * 0.35),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _cartItems.length,
                      itemBuilder: (_, i) {
                        final item = _cartItems[i];
                        final product =
                            item['product'] as Map<String, dynamic>?;
                        final productId =
                            item['productId'] as String? ??
                                (product?['id'] as String? ?? '');
                        final qty =
                            (item['quantity'] as num).toInt();
                        final price = product != null
                            ? (product['price'] as num).toDouble()
                            : 0.0;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius:
                                    BorderRadius.circular(8)),
                            child: const Icon(Icons.shopping_bag,
                                color: AppColors.primary, size: 22),
                          ),
                          title: Text(
                              product?['name'] as String? ?? '—',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              'R\$ ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.primary)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20),
                                onPressed: () async {
                                  await _updateCartQty(
                                      productId, qty - 1);
                                  setModalState(() {});
                                },
                              ),
                              Text('$qty',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: AppColors.primary),
                                onPressed: () async {
                                  await _updateCartQty(
                                      productId, qty + 1);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('R\$ ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _checkout(userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Finalizar Compra',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                SizedBox(
                    height:
                        MediaQuery.of(ctx).viewInsets.bottom + 8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _showCart,
              ),
              if (_totalCartItems > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle),
                    constraints: const BoxConstraints(
                        minWidth: 16, minHeight: 16),
                    child: Text('$_totalCartItems',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
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
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off,
                                size: 48,
                                color: AppColors.greyLight),
                            const SizedBox(height: 8),
                            const Text(
                                'Não foi possível carregar os produtos',
                                style: TextStyle(color: AppColors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadAll,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary),
                              child: const Text('Tentar novamente',
                                  style:
                                      TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 48,
                                    color: AppColors.greyLight),
                                SizedBox(height: 8),
                                Text('Nenhum produto encontrado',
                                    style:
                                        TextStyle(color: AppColors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAll,
                            child: GridView.builder(
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
                              itemBuilder: (ctx, i) => _ProductCard(
                                product: _products[i],
                                cartQty: _cartQtyFor(
                                    _products[i]['id'] as String),
                                onAdd: () => _addToCart(_products[i]),
                              ),
                            ),
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
                Text(product['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.dark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product['brand'] ?? '',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey)),
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
                            ? Text('$cartQty',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))
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
