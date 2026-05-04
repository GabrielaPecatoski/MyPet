import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
        '${ApiConstants.bookingsEndpoint}/user/$userId',
        token: token,
      );
      if (mounted) {
        final all = (data as List<dynamic>)
            .map((b) => b as Map<String, dynamic>)
            .toList();
        setState(() {
          _bookings = all
              .where((b) =>
                  b['status'] == 'CONCLUIDO' || b['status'] == 'RECUSADO')
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
        'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
      ];
      return '${dt.day} de ${months[dt.month - 1]} de ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  void _showAvaliarDialog(Map<String, dynamic> booking) {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Avaliar Serviço',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.dark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Como foi sua experiência?',
                  style: TextStyle(fontSize: 13, color: AppColors.dark)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () =>
                        setDialogState(() => selectedRating = star),
                    icon: Icon(
                      star <= selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      color: star <= selectedRating
                          ? const Color(0xFFFFC107)
                          : AppColors.grey,
                      size: 32,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  );
                }),
              ),
              const SizedBox(height: 12),
              const Text('Comentário (opcional)',
                  style: TextStyle(fontSize: 13, color: AppColors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.greyLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.greyLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.post(
                          '/reviews',
                          {
                            'userId': auth.user!.id,
                            'userName': auth.user!.name,
                            'establishmentId':
                                booking['establishmentId'] as String,
                            'bookingId': booking['id'] as String,
                            'rating': selectedRating,
                            'comment': commentCtrl.text.trim(),
                          },
                          token: auth.token,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avaliação enviada!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao enviar avaliação'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enviar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReclamarDialog(Map<String, dynamic> booking) {
    final assuntoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Registrar Reclamação',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.dark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: assuntoCtrl,
              decoration: const InputDecoration(labelText: 'Assunto'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (assuntoCtrl.text.trim().isEmpty ||
                  descCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiService.post(
                  '/reviews/complaints',
                  {
                    'userId': auth.user!.id,
                    'userName': auth.user!.name,
                    'establishmentId':
                        booking['establishmentId'] as String,
                    'bookingId': booking['id'] as String,
                    'subject': assuntoCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                  },
                  token: auth.token,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reclamação registrada!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao registrar reclamação'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enviar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        items: clientNavItems,
        onTap: (i) {
          if (i == 4) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (r) => false,
                arguments: i);
          }
        },
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _bookings.isEmpty
              ? const Center(
                  child: Text('Nenhum histórico encontrado',
                      style: TextStyle(color: AppColors.grey)))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (ctx, i) => _HistoryCard(
                      booking: _bookings[i],
                      formatDate: _formatDate,
                      onAvaliar: () => _showAvaliarDialog(_bookings[i]),
                      onReclamar: () => _showReclamarDialog(_bookings[i]),
                    ),
                  ),
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String Function(String?) formatDate;
  final VoidCallback onAvaliar;
  final VoidCallback onReclamar;

  const _HistoryCard({
    required this.booking,
    required this.formatDate,
    required this.onAvaliar,
    required this.onReclamar,
  });

  @override
  Widget build(BuildContext context) {
    final isConcluido = booking['status'] == 'CONCLUIDO';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.pets,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking['petName'] as String? ?? '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark)),
                    Text(booking['serviceName'] as String? ?? '—',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConcluido
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isConcluido ? 'Concluído' : 'Recusado',
                  style: TextStyle(
                      color: isConcluido
                          ? AppColors.success
                          : AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(Icons.location_on_outlined,
              booking['establishmentName'] as String? ?? '—'),
          const SizedBox(height: 4),
          _row(Icons.calendar_today_outlined,
              formatDate(booking['scheduledAt'] as String?)),
          if (booking['price'] != null) ...[
            const SizedBox(height: 4),
            _row(Icons.attach_money,
                'R\$ ${(booking['price'] as num).toStringAsFixed(2)}'),
          ],
          if (isConcluido) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAvaliar,
                    icon: const Icon(Icons.star_outline,
                        size: 16, color: AppColors.warning),
                    label: const Text('Avaliar',
                        style: TextStyle(color: AppColors.warning)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReclamar,
                    icon: const Icon(Icons.report_outlined,
                        size: 16, color: AppColors.danger),
                    label: const Text('Reclamar',
                        style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 4),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.grey))),
        ],
      );
}
