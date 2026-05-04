import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/mypet_app_bar.dart';

class EstabProdutosScreen extends StatefulWidget {
  const EstabProdutosScreen({super.key});
  @override
  State<EstabProdutosScreen> createState() => _EstabProdutosScreenState();
}

class _EstabProdutosScreenState extends State<EstabProdutosScreen> {
  String? _estabId;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final estabData =
          await ApiService.get('/establishments/owner/$userId', token: token);
      final list = estabData as List<dynamic>;
      if (list.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final estabId = (list.first as Map<String, dynamic>)['id'] as String;
      final prodData = await ApiService.get(
          '/marketplace/establishments/$estabId/products',
          token: token);
      if (mounted) {
        setState(() {
          _estabId = estabId;
          _products = (prodData as List<dynamic>)
              .map((p) => p as Map<String, dynamic>)
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFormDialog({Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nameCtrl =
        TextEditingController(text: isEdit ? product['name'] as String? : '');
    final descCtrl = TextEditingController(
        text: isEdit ? product['description'] as String? ?? '' : '');
    final priceCtrl = TextEditingController(
        text: isEdit
            ? (product['price'] as num).toStringAsFixed(2)
            : '');
    final categoryCtrl = TextEditingController(
        text: isEdit ? product['category'] as String? ?? '' : '');
    final stockCtrl = TextEditingController(
        text: isEdit ? '${product['stock'] ?? product['quantity'] ?? 0}' : '');
    final token = context.read<AuthProvider>().token;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Editar Produto' : 'Novo Produto',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Nome do produto'),
              const SizedBox(height: 10),
              _field(descCtrl, 'Descrição', maxLines: 2),
              const SizedBox(height: 10),
              _field(priceCtrl, 'Preço (R\$)',
                  inputType: TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 10),
              _field(categoryCtrl, 'Categoria'),
              const SizedBox(height: 10),
              _field(stockCtrl, 'Estoque (unidades)',
                  inputType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  priceCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final body = {
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                'category': categoryCtrl.text.trim(),
                'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
              };
              try {
                if (isEdit) {
                  await ApiService.patch(
                      '/marketplace/products/${product['id']}', body,
                      token: token);
                } else {
                  await ApiService.post(
                      '/marketplace/establishments/$_estabId/products', body,
                      token: token);
                }
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        isEdit ? 'Produto atualizado!' : 'Produto cadastrado!'),
                    backgroundColor: AppColors.success,
                  ));
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Erro ao salvar produto'),
                    backgroundColor: AppColors.danger,
                  ));
                }
              }
            },
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover produto'),
        content: const Text('Deseja remover este produto do catálogo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = context.read<AuthProvider>().token;
    try {
      await ApiService.delete('/marketplace/products/$id', token: token);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Produto removido'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao remover produto'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Widget _field(TextEditingController ctrl, String label,
      {int maxLines = 1, TextInputType? inputType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.greyLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.greyLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _estabId == null ? null : () => _showFormDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Produto',
            style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Catálogo de Produtos',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_products.length} itens',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 48, color: AppColors.greyLight),
                              const SizedBox(height: 12),
                              const Text('Nenhum produto cadastrado',
                                  style: TextStyle(color: AppColors.grey)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed:
                                    _estabId == null ? null : _showFormDialog,
                                child: const Text('Adicionar primeiro produto'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _products.length,
                            itemBuilder: (ctx, i) =>
                                _ProductCard(
                              product: _products[i],
                              onEdit: () =>
                                  _showFormDialog(product: _products[i]),
                              onDelete: () =>
                                  _deleteProduct(_products[i]['id'] as String),
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
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '—';
    final description = product['description'] as String? ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final category = product['category'] as String? ?? '';
    final stock =
        (product['stock'] ?? product['quantity'] ?? 0) as num;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.dark)),
                      if (category.isNotEmpty)
                        Text(category,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.grey)),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stock > 0
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stock > 0 ? 'Estoque: $stock' : 'Sem estoque',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: stock > 0
                            ? AppColors.success
                            : AppColors.danger),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.primary, size: 20),
                  tooltip: 'Editar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 20),
                  tooltip: 'Remover',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
