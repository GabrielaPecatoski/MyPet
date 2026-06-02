import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../core/colors.dart';
=======
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
import '../widgets/mypet_app_bar.dart';

class EstabProdutosScreen extends StatefulWidget {
  const EstabProdutosScreen({super.key});
  @override
  State<EstabProdutosScreen> createState() => _EstabProdutosScreenState();
}

class _EstabProdutosScreenState extends State<EstabProdutosScreen> {
<<<<<<< HEAD
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
=======
  final _searchCtrl = TextEditingController();
  String _filter = 'Todos';
  String _searchQuery = '';
  bool _loading = true;
  String? _estabId;
  String? _token;

  final List<_Product> _products = [];

  static const _categories = ['Higiene', 'Alimentação', 'Acessórios', 'Brinquedos', 'Saúde'];

  static const _categoryColors = {
    'Higiene': Color(0xFF06B6D4),
    'Alimentação': Color(0xFF22C55E),
    'Acessórios': Color(0xFFF59E0B),
    'Brinquedos': Color(0xFFEC4899),
    'Saúde': Color(0xFF8B5CF6),
  };

  static const _categoryIcons = {
    'Higiene': Icons.bubble_chart_outlined,
    'Alimentação': Icons.restaurant_outlined,
    'Acessórios': Icons.redeem_outlined,
    'Brinquedos': Icons.toys_outlined,
    'Saúde': Icons.health_and_safety_outlined,
  };

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _token = auth.token;
    _loadData(auth.user?.id);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData(String? userId) async {
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final estabData = await ApiService.get('/establishments/owner/$userId', token: _token);
      final estabs = estabData is List ? estabData : [estabData];
      if (estabs.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final id = (estabs.first as Map<String, dynamic>)['id'] as String? ?? '';
      _estabId = id;
      await _loadProducts();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProducts() async {
    if (_estabId == null) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
        '/marketplace/products/establishment/$_estabId',
        token: _token,
      );
      final list = (data as List).cast<Map<String, dynamic>>();
      setState(() {
        _products.clear();
        _products.addAll(list.map((e) => _Product.fromJson(e)));
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<_Product> get _filtered {
    var list = _products.where((p) {
      if (_filter == 'Ativos') return p.active;
      if (_filter == 'Inativos') return !p.active;
      if (_filter == 'Sem estoque') return p.stock == 0;
      return true;
    }).toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  int get _totalAtivos => _products.where((p) => p.active).length;
  double get _receitaTotal => _products.fold(0, (s, p) => s + p.price * p.stock);

  void _addProduct() => _showProductDialog();
  void _editProduct(_Product p) => _showProductDialog(product: p);

  Future<void> _toggleActive(_Product p) async {
    if (_estabId == null) return;
    try {
      await ApiService.patch(
        '/marketplace/products/${p.id}',
        {'active': !p.active},
        token: _token,
      );
      await _loadProducts();
    } catch (_) {}
  }

  Future<void> _deleteProduct(_Product p) async {
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
<<<<<<< HEAD
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
=======
        title: const Text('Remover produto',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Deseja remover "${p.name}"? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
<<<<<<< HEAD
    if (ok == true) setState(() => _products.remove(p));
=======
    if (ok == true && mounted) {
      try {
        await ApiService.delete('/marketplace/products/${p.id}', token: _token);
        await _loadProducts();
      } catch (_) {}
    }
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  }

  void _showProductDialog({_Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
<<<<<<< HEAD
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
=======
    final brandCtrl = TextEditingController(text: product?.brand ?? '');
    final priceCtrl = TextEditingController(
        text: product != null ? product.price.toStringAsFixed(2) : '');
    final stockCtrl =
        TextEditingController(text: product?.stock.toString() ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final unitCtrl = TextEditingController(text: product?.unit ?? 'Un');
    String category = product?.category ?? 'Higiene';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
<<<<<<< HEAD
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
=======
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  product == null ? 'Novo Produto' : 'Editar Produto',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark),
                ),
                const SizedBox(height: 20),

                const Text('Categoria',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.map((c) {
                      final sel = category == c;
                      final color = _categoryColors[c] ?? AppColors.primary;
                      return GestureDetector(
                        onTap: () => setS(() => category = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? color : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? color : AppColors.greyLight),
                          ),
                          child: Text(c,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: sel ? Colors.white : AppColors.grey)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                _dlgField('Nome do produto', nameCtrl,
                    hint: 'Ex: Shampoo Pet Premium'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _dlgField('Marca', brandCtrl, hint: 'Ex: PetLove')),
                    const SizedBox(width: 12),
                    Expanded(child: _dlgField('Unidade', unitCtrl, hint: 'Ex: Un, kg, ml')),
                  ],
                ),
                const SizedBox(height: 12),
                _dlgField('Descrição (opcional)', descCtrl,
                    hint: 'Breve descrição do produto', maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _dlgField('Preço (R\$)', priceCtrl,
                            hint: '0,00', isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _dlgField('Estoque', stockCtrl,
                            hint: '0', isNumber: true)),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final price =
                          double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                      final stock = int.tryParse(stockCtrl.text) ?? 0;
                      Navigator.pop(ctx);
                      try {
                        final desc = descCtrl.text.trim();
                        if (product == null) {
                          final body = <String, dynamic>{
                            'establishmentId': _estabId,
                            'name': name,
                            'brand': brandCtrl.text.trim(),
                            'unit': unitCtrl.text.trim().isEmpty ? 'Un' : unitCtrl.text.trim(),
                            'category': category,
                            'price': price,
                            'stock': stock,
                          };
                          if (desc.isNotEmpty) body['description'] = desc;
                          await ApiService.post('/marketplace/products', body, token: _token);
                        } else {
                          final body = <String, dynamic>{
                            'name': name,
                            'brand': brandCtrl.text.trim(),
                            'unit': unitCtrl.text.trim().isEmpty ? 'Un' : unitCtrl.text.trim(),
                            'category': category,
                            'price': price,
                            'stock': stock,
                          };
                          if (desc.isNotEmpty) body['description'] = desc;
                          await ApiService.patch('/marketplace/products/${product.id}', body, token: _token);
                        }
                        await _loadProducts();
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      product == null ? 'Adicionar Produto' : 'Salvar Alterações',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _field(String label, TextEditingController ctrl, {bool isNumber = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
=======
  Widget _dlgField(String label, TextEditingController ctrl,
      {String hint = '', bool isNumber = false, int maxLines = 1}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
<<<<<<< HEAD
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
=======
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.greyLight)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.greyLight)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5)),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Meu Catálogo',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.dark)),
                                SizedBox(height: 2),
                                Text('Gerencie seus produtos',
                                    style:
                                        TextStyle(fontSize: 13, color: AppColors.grey)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _estabId != null ? _addProduct : null,
                            icon: const Icon(Icons.add, size: 18, color: Colors.white),
                            label: const Text('Produto',
                                style: TextStyle(color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _StatChip(
                              label: '${_products.length} produtos',
                              icon: Icons.inventory_2_outlined,
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          _StatChip(
                              label: '$_totalAtivos ativos',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success),
                          const SizedBox(width: 8),
                          _StatChip(
                              label: 'R\$ ${(_receitaTotal / 1000).toStringAsFixed(1)}k',
                              icon: Icons.trending_up,
                              color: const Color(0xFF6366F1)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Buscar produto ou categoria...',
                          hintStyle:
                              const TextStyle(color: AppColors.grey, fontSize: 14),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.grey, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      color: AppColors.grey, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Divider(height: 1, color: AppColors.greyLight),
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: ['Todos', 'Ativos', 'Inativos', 'Sem estoque']
                              .map((f) {
                            final sel = _filter == f;
                            return GestureDetector(
                              onTap: () => setState(() => _filter = f),
                              child: Container(
                                margin: const EdgeInsets.only(right: 20),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(f,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: sel
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: sel
                                                ? AppColors.primary
                                                : AppColors.grey)),
                                    const SizedBox(height: 4),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 2,
                                      width: sel ? 32 : 0,
                                      decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(1)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(36)),
                                child: const Icon(Icons.inventory_2_outlined,
                                    size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Nenhum resultado para "$_searchQuery"'
                                    : 'Nenhum produto nesta categoria',
                                style: const TextStyle(
                                    color: AppColors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => _ProductCard(
                            product: filtered[i],
                            categoryColor:
                                _categoryColors[filtered[i].category] ?? AppColors.primary,
                            categoryIcon:
                                _categoryIcons[filtered[i].category] ?? Icons.shopping_bag_outlined,
                            onEdit: () => _editProduct(filtered[i]),
                            onToggle: () => _toggleActive(filtered[i]),
                            onDelete: () => _deleteProduct(filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    );
  }
}

<<<<<<< HEAD
class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
=======
class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label, required this.icon, required this.color});
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

  @override
  Widget build(BuildContext context) {
    return Container(
<<<<<<< HEAD
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
=======
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _Product product;
<<<<<<< HEAD
=======
  final Color categoryColor;
  final IconData categoryIcon;
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  final VoidCallback onEdit, onToggle, onDelete;

  const _ProductCard({
    required this.product,
<<<<<<< HEAD
=======
    required this.categoryColor,
    required this.categoryIcon,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    final isOut = product.stock == 0;
    final isInactive = !product.active;

    return Opacity(
      opacity: isInactive ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))
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
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(product.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isInactive
                                          ? AppColors.grey
                                          : AppColors.dark)),
                            ),
                            const SizedBox(width: 6),
                            if (isInactive)
                              _Badge('Inativo', AppColors.grey)
                            else if (isOut)
                              _Badge('Sem estoque', AppColors.warning)
                            else
                              _Badge('Em estoque', AppColors.success,
                                  small: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(product.category,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: categoryColor)),
                        ),
                        if (product.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(product.description,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('R\$ ${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isInactive
                                        ? AppColors.grey
                                        : AppColors.primary)),
                            const Spacer(),
                            _InfoPill(Icons.inventory_2_outlined,
                                '${product.stock} ${product.unit}', AppColors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.greyLight.withValues(alpha: 0.7),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  _ActionBtn(Icons.edit_outlined, 'Editar', AppColors.primary,
                      onEdit),
                  _vDivider(),
                  _ActionBtn(
                    isInactive
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    isInactive ? 'Ativar' : 'Pausar',
                    isInactive ? AppColors.success : AppColors.grey,
                    onToggle,
                  ),
                  _vDivider(),
                  _ActionBtn(Icons.delete_outline, 'Excluir', AppColors.danger,
                      onDelete),
                ],
              ),
            ),
          ],
        ),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
      ),
    );
  }

<<<<<<< HEAD
  Widget _vDivider() => Container(
        width: 1, height: 32, color: AppColors.greyLight);
=======
  Widget _vDivider() =>
      Container(width: 1, color: AppColors.greyLight.withValues(alpha: 0.7));
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final bool small;
  const _Badge(this.text, this.color, {this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoPill(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
<<<<<<< HEAD

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
=======
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
<<<<<<< HEAD
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
=======
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
<<<<<<< HEAD
              const SizedBox(width: 4),
=======
              const SizedBox(width: 5),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
  String category;
  double price;
  int stock;
  int sold;
=======
  String brand;
  String unit;
  String category;
  String description;
  double price;
  int stock;
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  bool active;

  _Product({
    required this.id,
    required this.name,
<<<<<<< HEAD
    required this.category,
    required this.price,
    required this.stock,
    required this.sold,
    required this.active,
  });
=======
    this.brand = '',
    this.unit = 'Un',
    required this.category,
    this.description = '',
    required this.price,
    required this.stock,
    required this.active,
  });

  factory _Product.fromJson(Map<String, dynamic> json) => _Product(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        unit: json['unit'] as String? ?? 'Un',
        category: json['category'] as String? ?? 'Higiene',
        description: json['description'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        active: json['active'] as bool? ?? true,
      );
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
}
