import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/mypet_app_bar.dart';

class EstabAvaliacoesScreen extends StatefulWidget {
  const EstabAvaliacoesScreen({super.key});
  @override
  State<EstabAvaliacoesScreen> createState() => _EstabAvaliacoesScreenState();
}

class _EstabAvaliacoesScreenState extends State<EstabAvaliacoesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
      final estabData = await ApiService.get(
        '/establishments/owner/$userId',
        token: token,
      );
      final list = estabData as List<dynamic>;
      if (list.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final estabId = (list.first as Map<String, dynamic>)['id'] as String;

      final results = await Future.wait([
        ApiService.get('/reviews/establishment/$estabId', token: token),
        ApiService.get(
            '/reviews/complaints/establishment/$estabId', token: token),
      ]);

      if (mounted) {
        setState(() {
          _reviews = (results[0] as List<dynamic>)
              .map((r) => r as Map<String, dynamic>)
              .toList();
          _complaints = (results[1] as List<dynamic>)
              .map((c) => c as Map<String, dynamic>)
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(
        0, (s, r) => s + (r['rating'] as num).toDouble());
    return sum / _reviews.length;
  }

  int get _pendentesCount =>
      _complaints.where((c) => c['status'] == 'PENDENTE').length;

  void _showResponderDialog(Map<String, dynamic> complaint) {
    final responseCtrl = TextEditingController();
    final token = context.read<AuthProvider>().token;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Responder Reclamação',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: responseCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escreva sua resposta...',
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
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (responseCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiService.patch(
                  '/reviews/complaints/${complaint['id']}/respond',
                  {'response': responseCtrl.text.trim()},
                  token: token,
                );
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Resposta enviada!'),
                    backgroundColor: AppColors.success,
                  ));
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Erro ao responder'),
                    backgroundColor: AppColors.danger,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child:
                const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('$_pendentesCount', 'Pendentes'),
                      _statItem('${_reviews.length}', 'Avaliações'),
                      _statItem(
                          _avgRating.toStringAsFixed(1), 'Nota Média'),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabCtrl,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.grey,
                    labelStyle:
                        const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Avaliações'),
                      Tab(text: 'Reclamações'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildReviews(),
                      _buildComplaints(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReviews() {
    if (_reviews.isEmpty) {
      return const Center(
        child: Text('Nenhuma avaliação ainda',
            style: TextStyle(color: AppColors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_reviews.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    _avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < _avgRating.floor()
                                ? Icons.star
                                : (_avgRating - i >= 0.5
                                    ? Icons.star_half
                                    : Icons.star_border),
                            color: const Color(0xFFFFC107),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${_reviews.length} avaliações',
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ..._reviews.map((r) => _ReviewCard(r: r, formatDate: _formatDate)),
        ],
      ),
    );
  }

  Widget _buildComplaints() {
    if (_complaints.isEmpty) {
      return const Center(
        child: Text('Nenhuma reclamação',
            style: TextStyle(color: AppColors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _complaints
            .map((c) => _ComplaintCard(
                  c: c,
                  formatDate: _formatDate,
                  onResponder: () => _showResponderDialog(c),
                ))
            .toList(),
      ),
    );
  }

  Widget _statItem(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> r;
  final String Function(String?) formatDate;
  const _ReviewCard({required this.r, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final rating = (r['rating'] as num).toInt();
    final name = r['userName'] as String? ?? 'Usuário';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(formatDate(r['createdAt'] as String?),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFC107),
                          size: 14,
                        )),
              ),
            ],
          ),
          if (r['comment'] != null &&
              (r['comment'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r['comment'] as String,
                style: const TextStyle(fontSize: 13, color: AppColors.grey)),
          ],
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> c;
  final String Function(String?) formatDate;
  final VoidCallback onResponder;
  const _ComplaintCard(
      {required this.c,
      required this.formatDate,
      required this.onResponder});

  @override
  Widget build(BuildContext context) {
    final status = c['status'] as String? ?? 'PENDENTE';
    final isPendente = status == 'PENDENTE';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPendente
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.greyLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c['subject'] as String? ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.dark)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPendente
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: isPendente
                            ? AppColors.warning
                            : AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(c['userName'] as String? ?? '—',
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          Text(formatDate(c['createdAt'] as String?),
              style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          const SizedBox(height: 6),
          Text(c['description'] as String? ?? '',
              style: const TextStyle(fontSize: 13, color: AppColors.dark)),
          if (c['response'] != null &&
              (c['response'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sua resposta:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(c['response'] as String,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.dark)),
                ],
              ),
            ),
          ],
          if (isPendente) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onResponder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Responder',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
