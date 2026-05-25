import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/api_service.dart';
import '../core/constants.dart';
import '../widgets/mypet_app_bar.dart';

class EstabProdutosScreen extends StatefulWidget {
  const EstabProdutosScreen({super.key});
  @override
  State<EstabProdutosScreen> createState() => _EstabProdutosScreenState();
}

class _EstabProdutosScreenState extends State<EstabProdutosScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'Todos';
  String _searchQuery = '';
  List<Map<String, dynamic>> _products = [];
  bool _loading = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? get _estabId =>
      context.read<EstablishmentProvider>().establishmentId;

  Future<void> _loadProducts() async {
    final estabId = _estabId;
    if (estabId == null) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
        '${ApiConstants.productsEndpoint}?establishmentId=$estabId',
      );
      setState(() => _products = (data as List).cast<Map<String, dynamic>>());
    } catch (_) {
      setState(() => _products = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _products.where((p) {
      final active = p['active'] as bool? ?? true;
      final stock = p['stock'] as int? ?? 0;
      if (_filter == 'Ativos') return active;
      if (_filter == 'Inativos') return !active;
      if (_filter == 'Sem estoque') return stock == 0;
      return true;
    }).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final cat = (p['category'] as String? ?? '').toLowerCase();
        return name.contains(q) || cat.contains(q);
      }).toList();
    }
    return list;
  }

  int get _totalAtivos =>
      _products.where((p) => p['active'] as bool? ?? true).length;

  double get _receitaTotal => _products.fold(0.0, (s, p) {
        final price = (p['price'] as num?)?.toDouble() ?? 0.0;
        final sold = p['sold'] as int? ?? 0;
        return s + price * sold;
      });

  Future<void> _toggleActive(Map<String, dynamic> p) async {
    final current = p['active'] as bool? ?? true;
    try {
      await ApiService.patch(
        '${ApiConstants.productsEndpoint}/${p['id']}',
        {'active': !current},
      );
      await _loadProducts();
    } catch (_) {}
  }

  Future<void> _deleteProduct(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover produto',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Deseja remover "${p['name']}"? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await ApiService.delete('${ApiConstants.productsEndpoint}/${p['id']}');
        await _loadProducts();
      } catch (_) {}
    }
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final nameCtrl = TextEditingController(text: product?['name'] as String? ?? '');
    final priceCtrl = TextEditingController(
        text: product != null
            ? (product['price'] as num).toStringAsFixed(2)
            : '');
    final stockCtrl =
        TextEditingController(text: (product?['stock'] as int?)?.toString() ?? '');
    final descCtrl =
        TextEditingController(text: product?['description'] as String? ?? '');
    String category = product?['category'] as String? ?? 'Higiene';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  product == null ? 'Novo Produto' : 'Editar Produto',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                const SizedBox(height: 20),
                const Text('Categoria',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? color : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? color : AppColors.greyLight),
                          ),
                          child: Text(c,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500,
                                  color: sel ? Colors.white : AppColors.grey)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _dlgField('Nome do produto', nameCtrl, hint: 'Ex: Shampoo Pet Premium', isNumber: false),
                const SizedBox(height: 12),
                _dlgField('Descrição (opcional)', descCtrl,
                    hint: 'Breve descrição', maxLines: 2, isNumber: false),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dlgField('Preço (R\$)', priceCtrl, hint: '0,00', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _dlgField('Estoque', stockCtrl, hint: '0', isNumber: true)),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final price =
                          double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
                      final stock = int.tryParse(stockCtrl.text) ?? 0;
                      Navigator.pop(ctx);
                      final estabId = _estabId;
                      try {
                        if (product == null) {
                          await ApiService.post(ApiConstants.productsEndpoint, {
                            'name': name,
                            'category': category,
                            'description': descCtrl.text.trim(),
                            'price': price,
                            'stock': stock,
                            'establishmentId': estabId,
                          });
                        } else {
                          await ApiService.patch(
                            '${ApiConstants.productsEndpoint}/${product['id']}',
                            {
                              'name': name,
                              'category': category,
                              'description': descCtrl.text.trim(),
                              'price': price,
                              'stock': stock,
                            },
                          );
                        }
                        if (mounted) await _loadProducts();
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      product == null ? 'Adicionar Produto' : 'Salvar Alterações',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dlgField(String label, TextEditingController ctrl,
      {String hint = '', bool isNumber = false, int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.grey, fontSize: 13),
            filled: true, fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.greyLight)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.greyLight)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Meu Catálogo',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark)),
                    SizedBox(height: 2),
                    Text('Gerencie seus produtos',
                        style: TextStyle(fontSize: 13, color: AppColors.grey)),
                  ]),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('Produto',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _StatChip(
                    label: '${_products.length} produtos',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                _StatChip(
                    label: '$_totalAtivos ativos',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Buscar produto ou categoria...',
                  hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.grey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppColors.grey, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true, fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
            ]),
          ),

          Container(
            color: Colors.white,
            child: Column(children: [
              const Divider(height: 1, color: AppColors.greyLight),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['Todos', 'Ativos', 'Inativos', 'Sem estoque'].map((f) {
                    final sel = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 20),
                        alignment: Alignment.center,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(f,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                  color: sel ? AppColors.primary : AppColors.grey)),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 2, width: sel ? 32 : 0,
                            decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(1)),
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            width: 72, height: 72,
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
                            style: const TextStyle(color: AppColors.grey, fontSize: 14),
                          ),
                        ]),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final p = filtered[i];
                            final cat = p['category'] as String? ?? '';
                            return _ProductCard(
                              product: p,
                              categoryColor: _categoryColors[cat] ?? AppColors.primary,
                              categoryIcon: _categoryIcons[cat] ?? Icons.shopping_bag_outlined,
                              onEdit: () => _showProductDialog(product: p),
                              onToggle: () => _toggleActive(p),
                              onDelete: () => _deleteProduct(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback onEdit, onToggle, onDelete;

  const _ProductCard({
    required this.product,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = !(product['active'] as bool? ?? true);
    final stock = product['stock'] as int? ?? 0;
    final isOut = stock == 0;
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final name = product['name'] as String? ?? '';
    final category = product['category'] as String? ?? '';
    final description = product['description'] as String? ?? '';

    return Opacity(
      opacity: isInactive ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14,
                              color: isInactive ? AppColors.grey : AppColors.dark)),
                    ),
                    const SizedBox(width: 6),
                    if (isInactive)
                      _Badge('Inativo', AppColors.grey)
                    else if (isOut)
                      _Badge('Sem estoque', AppColors.warning)
                    else
                      _Badge('Em estoque', AppColors.success, small: true),
                  ]),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(category,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: categoryColor)),
                  ),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(description,
                          style: const TextStyle(fontSize: 12, color: AppColors.grey),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('R\$ ${price.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15,
                            color: isInactive ? AppColors.grey : AppColors.primary)),
                    const Spacer(),
                    _InfoPill(Icons.inventory_2_outlined, '$stock un', AppColors.grey),
                  ]),
                ]),
              ),
            ]),
          ),
          Container(height: 1, color: AppColors.greyLight.withValues(alpha: 0.7)),
          IntrinsicHeight(
            child: Row(children: [
              _ActionBtn(Icons.edit_outlined, 'Editar', AppColors.primary, onEdit),
              _vDivider(),
              _ActionBtn(
                isInactive ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                isInactive ? 'Ativar' : 'Pausar',
                isInactive ? AppColors.success : AppColors.grey,
                onToggle,
              ),
              _vDivider(),
              _ActionBtn(Icons.delete_outline, 'Excluir', AppColors.danger, onDelete),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, color: AppColors.greyLight.withValues(alpha: 0.7));
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final bool small;
  const _Badge(this.text, this.color, {this.small = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoPill(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 3),
    Text(text, style: TextStyle(fontSize: 11, color: color)),
  ]);
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    ),
  );
}
