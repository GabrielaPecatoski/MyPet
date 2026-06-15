import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/order_status.dart';
import '../models/product.dart';
import '../models/product_history_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_products_provider.dart';
import '../providers/product_history_provider.dart';
import '../repositories/establishment_products_repository.dart';
import '../repositories/orders_repository.dart';
import '../widgets/app_image.dart';
import '../widgets/mypet_app_bar.dart';
import 'establishment_orders_view.dart';

class EstabProdutosScreen extends StatelessWidget {
  const EstabProdutosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return ChangeNotifierProvider(
      create: (_) =>
          EstablishmentProductsProvider(EstablishmentProductsRepository())
            ..load(auth.user?.id, token: auth.token),
      child: const _EstabProdutosView(),
    );
  }
}

class _EstabProdutosView extends StatefulWidget {
  const _EstabProdutosView();
  @override
  State<_EstabProdutosView> createState() => _EstabProdutosViewState();
}

class _EstabProdutosViewState extends State<_EstabProdutosView> {
  final _searchCtrl = TextEditingController();

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _editProduct(ProductModel p) => _showProductDialog(product: p);

  void _showSalesHistory(ProductModel p) {
    final auth = context.read<AuthProvider>();
    final estabId = context.read<EstablishmentProductsProvider>().estabId;
    if (estabId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ProductHistoryProvider(OrdersRepository())
          ..loadForStore(
            productId: p.id,
            establishmentId: estabId,
            token: auth.token,
          ),
        child: _SalesHistorySheet(product: p),
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<EstablishmentProductsProvider>().delete(p.id);
    }
  }

  void _showProductDialog({ProductModel? product}) {
    final provider = context.read<EstablishmentProductsProvider>();
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final brandCtrl = TextEditingController(text: product?.brand ?? '');
    final priceCtrl = TextEditingController(
        text: product != null ? product.price.toStringAsFixed(2) : '');
    final stockCtrl =
        TextEditingController(text: product?.stock.toString() ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final unitCtrl = TextEditingController(text: product?.unit ?? 'Un');
    String category = product?.category ?? 'Higiene';
    String? imageData = product?.imageUrl;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                Center(
                  child: _ProductImagePicker(
                    initial: imageData,
                    onChanged: (url) => imageData = url,
                  ),
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
                      final color = _categoryColors[c] ?? AppColors.estab;
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
                      final desc = descCtrl.text.trim();
                      final fields = <String, dynamic>{
                        'name': name,
                        'brand': brandCtrl.text.trim(),
                        'unit': unitCtrl.text.trim().isEmpty
                            ? 'Un'
                            : unitCtrl.text.trim(),
                        'category': category,
                        'price': price,
                        'stock': stock,
                      };
                      if (desc.isNotEmpty) fields['description'] = desc;
                      if (imageData != null) fields['imageUrl'] = imageData;
                      Navigator.pop(ctx);
                      if (product == null) {
                        await provider.create(fields);
                      } else {
                        await provider.update(product.id, fields);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.estab,
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
        ),
      ),
    );
  }

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
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
                      const BorderSide(color: AppColors.estab, width: 1.5)),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EstablishmentProductsProvider>();
    final filtered = provider.filtered;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MypetAppBar(showBack: false),
        body: Column(
          children: [
            Material(
              color: Colors.white,
              elevation: 0.5,
              shadowColor: Colors.black12,
              child: const TabBar(
                labelColor: AppColors.estab,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: AppColors.estab,
                indicatorWeight: 2.5,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: [Tab(text: 'Produtos'), Tab(text: 'Pedidos')],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  provider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.estab))
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
                            onPressed: provider.estabId != null
                                ? () => _showProductDialog()
                                : null,
                            icon: const Icon(Icons.add, size: 18, color: Colors.white),
                            label: const Text('Produto',
                                style: TextStyle(color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.estab,
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
                              label: '${provider.totalProducts} produtos',
                              icon: Icons.inventory_2_outlined,
                              color: AppColors.estab),
                          const SizedBox(width: 8),
                          _StatChip(
                              label: '${provider.totalAtivos} ativos',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success),
                          const SizedBox(width: 8),
                          _StatChip(
                              label: 'R\$ ${(provider.receitaTotal / 1000).toStringAsFixed(1)}k',
                              icon: Icons.trending_up,
                              color: const Color(0xFF6366F1)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => provider.setSearch(v),
                        decoration: InputDecoration(
                          hintText: 'Buscar produto ou categoria...',
                          hintStyle:
                              const TextStyle(color: AppColors.grey, fontSize: 14),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.grey, size: 20),
                          suffixIcon: provider.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      color: AppColors.grey, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    provider.setSearch('');
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
                                  color: AppColors.estab, width: 1.5)),
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
                            final sel = provider.filter == f;
                            return GestureDetector(
                              onTap: () => provider.setFilter(f),
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
                                                ? AppColors.estab
                                                : AppColors.grey)),
                                    const SizedBox(height: 4),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: 2,
                                      width: sel ? 32 : 0,
                                      decoration: BoxDecoration(
                                          color: AppColors.estab,
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
                                    size: 36, color: AppColors.estab),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.searchQuery.isNotEmpty
                                    ? 'Nenhum resultado para "${provider.searchQuery}"'
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
                                _categoryColors[filtered[i].category] ?? AppColors.estab,
                            categoryIcon:
                                _categoryIcons[filtered[i].category] ?? Icons.shopping_bag_outlined,
                            onEdit: () => _editProduct(filtered[i]),
                            onToggle: () => provider.toggleActive(filtered[i]),
                            onDelete: () => _deleteProduct(filtered[i]),
                            onHistory: () => _showSalesHistory(filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
                  const EstabPedidosView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImagePicker extends StatefulWidget {
  final String? initial;
  final ValueChanged<String> onChanged;
  const _ProductImagePicker({this.initial, required this.onChanged});

  @override
  State<_ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<_ProductImagePicker> {
  String? _imageData;

  @override
  void initState() {
    super.initState();
    _imageData = widget.initial;
  }

  Future<void> _pick(ImageSource source) async {
    if (kIsWeb) return;
    final picked = await ImagePicker().pickImage(
        source: source, imageQuality: 75, maxWidth: 800, maxHeight: 800);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    setState(() => _imageData = url);
    widget.onChanged(url);
  }

  void _showOptions() {
    if (kIsWeb) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.estab),
              title: const Text('Galeria de fotos'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: AppColors.estab),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showOptions,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: AppImage(
          url: _imageData,
          fit: BoxFit.cover,
          fallback: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppColors.estab, size: 26),
              SizedBox(height: 6),
              Text('Foto', style: TextStyle(fontSize: 11, color: AppColors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback onEdit, onToggle, onDelete, onHistory;

  const _ProductCard({
    required this.product,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
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
                    clipBehavior: Clip.antiAlias,
                    child: AppImage(
                      url: product.imageUrl,
                      fit: BoxFit.cover,
                      fallback:
                          Icon(categoryIcon, color: categoryColor, size: 26),
                    ),
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
                                        : AppColors.estab)),
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
                  _ActionBtn(Icons.receipt_long_outlined, 'Vendas',
                      const Color(0xFF6366F1), onHistory),
                  _vDivider(),
                  _ActionBtn(Icons.edit_outlined, 'Editar', AppColors.estab,
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
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
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

class _SalesHistorySheet extends StatelessWidget {
  final ProductModel product;
  const _SalesHistorySheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ProductHistoryProvider>();

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: Color(0xFF6366F1), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Histórico de vendas',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark)),
                    Text(product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.estab)),
            )
          else if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 44, color: AppColors.greyLight),
                    SizedBox(height: 10),
                    Text('Nenhuma venda registrada ainda',
                        style: TextStyle(color: AppColors.grey, fontSize: 14)),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _SummaryStat(
                  icon: Icons.inventory_2_outlined,
                  label: '${history.totalQuantity} ${product.unit} vendidas',
                  color: AppColors.estab,
                ),
                const SizedBox(width: 8),
                _SummaryStat(
                  icon: Icons.attach_money,
                  label: 'R\$ ${history.totalValue.toStringAsFixed(2)}',
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${history.orderCount} ${history.orderCount == 1 ? 'pedido' : 'pedidos'}',
                style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 4),
                itemCount: history.entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.greyLight),
                itemBuilder: (_, i) =>
                    _SaleRow(entry: history.entries[i], unit: product.unit),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SummaryStat(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final ProductHistoryEntry entry;
  final String unit;
  const _SaleRow({required this.entry, required this.unit});

  static String _statusLabel(String s) {
    switch (s) {
      case 'FINALIZADO':
        return 'Entregue';
      case 'A_CAMINHO':
        return 'A caminho';
      case 'ENVIANDO':
        return 'Em preparo';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = entry.date;
    final dateStr = d == null
        ? 'Data indisponível'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final color = OrderTracking.color(entry.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark)),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_statusLabel(entry.status),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.quantity} $unit',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark)),
              const SizedBox(height: 2),
              Text('R\$ ${entry.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

