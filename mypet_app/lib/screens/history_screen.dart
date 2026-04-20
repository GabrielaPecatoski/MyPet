import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static final _history = [
    _HistoryItem(
      petName: 'Rex',
      petInfo: 'Golden Retriever • 3 anos',
      establishment: 'Pet Shop Amor & Carinho',
      date: '17 de março de 2026',
      time: '14:00',
    ),
    _HistoryItem(
      petName: 'Rex',
      petInfo: 'Golden Retriever • 3 anos',
      establishment: 'Pet Shop Amor & Carinho',
      date: '17 de março de 2026',
      time: '14:00',
    ),
  ];

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
      body: _history.isEmpty
          ? const Center(
              child: Text('Nenhum histórico encontrado',
                  style: TextStyle(color: AppColors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (ctx, i) => _HistoryCard(item: _history[i]),
            ),
    );
  }
}

class _HistoryItem {
  final String petName;
  final String petInfo;
  final String establishment;
  final String date;
  final String time;
  const _HistoryItem({
    required this.petName,
    required this.petInfo,
    required this.establishment,
    required this.date,
    required this.time,
  });
}

class _HistoryCard extends StatelessWidget {
  final _HistoryItem item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
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
            offset: const Offset(0, 2),
          ),
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
                child: const Icon(Icons.pets, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.petName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark)),
                    Text(item.petInfo,
                        style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(Icons.location_on_outlined, item.establishment),
          const SizedBox(height: 4),
          _row(Icons.calendar_today_outlined, item.date),
          const SizedBox(height: 4),
          _row(Icons.access_time, item.time),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Ver detalhes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.grey,
                    side: const BorderSide(color: AppColors.greyLight),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAvaliarDialog(context),
                  icon: const Icon(Icons.star_outline, size: 16,
                      color: AppColors.warning),
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
                  onPressed: () {},
                  icon: const Icon(Icons.report_outlined, size: 16,
                      color: AppColors.danger),
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
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.dark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deixe sua opinião sobre o serviço que recebeu.',
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
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
                      star <= selectedRating ? Icons.star : Icons.star_border,
                      color: star <= selectedRating
                          ? const Color(0xFFFFC107)
                          : AppColors.grey,
                      size: 32,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  );
                }),
              ),
              const SizedBox(height: 12),
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
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.greyLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.greyLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Avaliação enviada!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Enviar Avaliação',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
