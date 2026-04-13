import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MyPetAppBar(),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom:12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(radius:26, backgroundColor: Color(0xFFD4A574), child: Icon(Icons.pets, color: Colors.white)),
              const SizedBox(width:12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rex', style: TextStyle(fontWeight: FontWeight.w700, fontSize:15)),
                Text('Golden Retriever - 3 anos', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
              ])),
            ]),
            const SizedBox(height:10),
            _row(Icons.location_on_outlined, 'Pet Shop Amor e Carinho'),
            const SizedBox(height:4),
            _row(Icons.calendar_today_outlined, '17 de marco de 2026'),
            const SizedBox(height:4),
            _row(Icons.access_time_outlined, '14:00'),
            const SizedBox(height:12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.remove_red_eye_outlined, size:16),
              label: const Text('Ver detalhes'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40), textStyle: const TextStyle(fontSize:13)),
            ),
            const SizedBox(height:8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.star_outline, size:16),
                label: const Text('Avaliar'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), textStyle: const TextStyle(fontSize:13)),
              )),
              const SizedBox(width:8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.error_outline, size:16, color: AppColors.danger),
                label: const Text('Reclamar', style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), side: const BorderSide(color: AppColors.danger), textStyle: const TextStyle(fontSize:13)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  static Widget _row(IconData icon, String text) => Row(
    children: [Icon(icon, size:15, color: AppColors.textSecondary), const SizedBox(width:8), Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize:13))],
  );
}
