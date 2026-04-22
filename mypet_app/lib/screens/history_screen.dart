import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AppointmentModel> _history = [];
  final Set<String> _reviewed = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService.get(
        '/bookings/user/${auth.user!.id}',
        token: auth.token,
      );
      final list = data as List;
      final all = list.map((e) => AppointmentModel.fromJson(e)).toList();

      final now = DateTime.now();
      for (final b in all) {
        if (b.status == 'CONFIRMADO' &&
            now.difference(b.date).inHours >= 4) {
          try {
            await BookingService.updateStatus(
              token: auth.token!,
              bookingId: b.id,
              status: 'CONCLUIDO',
            );
          } catch (_) {}
        }
      }

      final data2 = await ApiService.get(
        '/bookings/user/${auth.user!.id}',
        token: auth.token,
      );
      final all2 =
          (data2 as List).map((e) => AppointmentModel.fromJson(e)).toList();

      setState(() {
        _history = all2.where((b) => b.status == 'CONCLUIDO').toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _history.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(36),
                                ),
                                child: const Icon(Icons.history,
                                    size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('Nenhum histórico encontrado',
                                  style: TextStyle(
                                      color: AppColors.dark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              const Text('Seus serviços concluídos aparecerão aqui',
                                  style: TextStyle(
                                      color: AppColors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (ctx, i) => _HistoryCard(
                        appointment: _history[i],
                        reviewed: _reviewed.contains(_history[i].id),
                        onReviewed: () =>
                            setState(() => _reviewed.add(_history[i].id)),
                      ),
                    ),
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool reviewed;
  final VoidCallback onReviewed;
  const _HistoryCard({
    required this.appointment,
    required this.reviewed,
    required this.onReviewed,
  });

  @override
  Widget build(BuildContext context) {
    final d = appointment.date;
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    final dateStr = '${d.day} de ${months[d.month - 1]} de ${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.pets, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.petName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark)),
                    Text(
                      appointment.petBreed.isNotEmpty
                          ? '${appointment.petBreed}${appointment.petAge > 0 ? ' • ${appointment.petAge} anos' : ''}'
                          : appointment.serviceName,
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              if (reviewed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
                      SizedBox(width: 3),
                      Text('Avaliado',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF856404),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          _row(Icons.location_on_outlined, appointment.establishmentName),
          const SizedBox(height: 5),
          _row(Icons.calendar_today_outlined, dateStr),
          const SizedBox(height: 5),
          _row(Icons.access_time_outlined, appointment.time),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Ver detalhes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.grey,
                side: const BorderSide(color: AppColors.greyLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reviewed
                      ? null
                      : () => _showAvaliarDialog(context),
                  icon: Icon(
                    reviewed ? Icons.star : Icons.star_outline,
                    size: 16,
                    color: reviewed ? AppColors.greyLight : AppColors.warning,
                  ),
                  label: Text(
                    reviewed ? 'Avaliado' : 'Avaliar',
                    style: TextStyle(
                        color: reviewed ? AppColors.greyLight : AppColors.warning),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: reviewed
                            ? AppColors.greyLight
                            : AppColors.warning),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.report_outlined,
                      size: 16, color: AppColors.danger),
                  label: const Text('Reclamar',
                      style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.grey),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey))),
        ],
      );

  void _showAvaliarDialog(BuildContext context) {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Avaliar Serviço',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deixe sua opinião sobre o serviço que recebeu.',
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Como foi sua experiência?',
                style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () =>
                        setDialogState(() => selectedRating = star),
                    icon: Icon(
                      star <= selectedRating ? Icons.star : Icons.star_border,
                      color: star <= selectedRating
                          ? const Color(0xFFFFC107)
                          : AppColors.grey,
                      size: 34,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  );
                }),
              ),
              const SizedBox(height: 14),
              const Text('Deixe seu comentário (opcional)',
                  style: TextStyle(fontSize: 13, color: AppColors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
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
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedRating == 0
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final auth = context.read<AuthProvider>();
                        try {
                          await ReviewService.submitReview(
                            userId: auth.user?.id ?? '',
                            userName: auth.user?.name ?? 'Usuário',
                            establishmentId: appointment.establishmentId,
                            bookingId: appointment.id,
                            rating: selectedRating,
                            comment: commentCtrl.text.trim().isEmpty
                                ? null
                                : commentCtrl.text.trim(),
                            token: auth.token,
                          );
                        } catch (_) {
                        }
                        onReviewed();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avaliação enviada!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.greyLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Enviar Avaliação',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
