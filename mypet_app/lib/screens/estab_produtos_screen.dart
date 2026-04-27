import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/mypet_app_bar.dart';

class EstabProdutosScreen extends StatefulWidget {
  const EstabProdutosScreen({super.key});
  @override
  State<EstabProdutosScreen> createState() => _EstabProdutosScreenState();
}

class _EstabProdutosScreenState extends State<EstabProdutosScreen> {
  final List<_Product> _products = [
    _Product(id: '1', name: 'Shampoo Pet Premium', category: 'Higiene', price: 49.90, stock: 15, sold: 38, active: true),
    _Product(id: '2', name: 'Ração Golden Adulto 15kg', category: 'Alimentação', price: 189.90, stock: 0, sold: 22, active: true),
    _Product(id: '3', name: 'Arranhador Sisal Grande', category: 'Acessórios', price: 129.90, stock: 4, sold: 10, active: false),
    _Product(id: '4', name: 'Brinquedo Interativo', category: 'Brinquedos', price: 34.90, stock: 20, sold: 55, active: true),
    _Product(id: '5', name: 'Coleira Antipulgas', category: 'Saúde', price: 79.90, stock: 8, sold: 17, active: true),
  ];

  int get _totalProducts => _products.length;
  int get _activeProducts => _products.where((p) => p.active).length;
  int get _outOfStock => _products.where((p) => p.stock == 0).length;
  double get _totalValue =>
      _products.fold(0, (sum, p) => sum + p.price * p.stock);

  void _addProduct() {
    _showProductDialog();
  }

  void _editProduct(_Product p) {
    _showProductDialog(product: p);
  }

  void _toggleActive(_Product p) {
    setState(() => p.active = !p.active);
  }

  void _deleteProduct(_Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover produto?'),
        content: Text('Deseja remover "${p.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Não')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger, elevation: 0),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => _products.remove(p));
  }

  void _showProductDialog({_Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl =
        TextEditingController(text: product != null ? product.price.toStringAsFixed(2) : '');
    final stockCtrl =
        TextEditingController(text: product?.stock.toString() ?? '');
    String category = product?.category ?? 'Higiene';
    final categories = ['Higiene', 'Alimentação', 'Acessórios', 'Brinquedos', 'Saúde'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(product == null ? 'Novo Produto' : 'Editar Produto',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('Nome do produto', nameCtrl),
                const SizedBox(height: 12),
                const Text('Categoria',
                    style: TextStyle(fontSize: 13, color: AppColors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.greyLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.greyLight),
                    ),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setS(() => category = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field('Preço (R\$)', priceCtrl, isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Estoque', stockCtrl, isNumber: true)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppColors.grey))),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                final stock = int.tryParse(stockCtrl.text) ?? 0;
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                setState(() {
                  if (product == null) {
                    _products.add(_Product(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      category: category,
                      price: price,
                      stock: stock,
                      sold: 0,
                      active: true,
                    ));
                  } else {
                    product.name = name;
                    product.category = category;
                    product.price = price;
                    product.stock = stock;
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(product == null ? 'Adicionar' : 'Salvar',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool isNumber = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.greyLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.greyLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MypetAppBar(
        showBack: false,
        actions: [
          IconButton(
            onPressed: _addProduct,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            tooltip: 'Adicionar produto',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produtos',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark)),
            const SizedBox(height: 4),
            const Text('Gerencie seu catálogo de produtos',
                style: TextStyle(fontSize: 13, color: AppColors.grey)),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _SummaryCard(
                    label: 'Total',
                    value: '$_totalProducts',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primary),
                _SummaryCard(
                    label: 'Ativos',
                    value: '$_activeProducts',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success),
                _SummaryCard(
                    label: 'Sem estoque',
                    value: '$_outOfStock',
                    icon: Icons.warning_amber_outlined,
                    color: AppColors.warning),
                _SummaryCard(
                    label: 'Valor total',
                    value: 'R\$ ${_totalValue.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: const Color(0xFF6366F1)),
              ],
            ),

            const SizedBox(height: 20),

            ...(_products.map((p) => _ProductCard(
                  product: p,
                  onEdit: () => _editProduct(p),
                  onToggle: () => _toggleActive(p),
                  onDelete: () => _deleteProduct(p),
                ))),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Novo Produto', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final VoidCallback onEdit, onToggle, onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: product.active
                        ? AppColors.primaryLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: product.active ? AppColors.primary : AppColors.grey,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(product.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: product.active
                                        ? AppColors.dark
                                        : AppColors.grey)),
                          ),
                          if (!product.active)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.greyLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Inativo',
                                  style: TextStyle(
                                      fontSize: 10, color: AppColors.grey)),
                            ),
                          if (isOutOfStock && product.active)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Sem estoque',
                                  style: TextStyle(
                                      fontSize: 10, color: AppColors.warning)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(product.category,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('R\$ ${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary)),
                          const Spacer(),
                          const Icon(Icons.inventory_2_outlined,
                              size: 13, color: AppColors.grey),
                          const SizedBox(width: 3),
                          Text('${product.stock} un.',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.grey)),
                          const SizedBox(width: 10),
                          const Icon(Icons.shopping_cart_outlined,
                              size: 13, color: AppColors.grey),
                          const SizedBox(width: 3),
                          Text('${product.sold} vendidos',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.greyLight),
          Row(
            children: [
              _ActionBtn(
                icon: Icons.edit_outlined,
                label: 'Editar',
                color: AppColors.primary,
                onTap: onEdit,
              ),
              _vDivider(),
              _ActionBtn(
                icon: product.active
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                label: product.active ? 'Desativar' : 'Ativar',
                color: product.active ? AppColors.grey : AppColors.success,
                onTap: onToggle,
              ),
              _vDivider(),
              _ActionBtn(
                icon: Icons.delete_outline,
                label: 'Remover',
                color: AppColors.danger,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1, height: 32, color: AppColors.greyLight);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Product {
  final String id;
  String name;
  String category;
  double price;
  int stock;
  int sold;
  bool active;

  _Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.sold,
    required this.active,
  });
}
