import 'package:flutter/material.dart';
import '../core/colors.dart';

class DriverHistoricoScreen extends StatelessWidget {
  const DriverHistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            const SizedBox(height: 16),
            _statsCard(),
            const SizedBox(height: 20),
            _emptyList(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: AppColors.driver, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MY PET · MOTORISTA',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey,
                      letterSpacing: 0.8)),
              Text('Histórico',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark)),
            ],
          ),
        ],
      );

  Widget _statsCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(Icons.route, AppColors.driver, '0', 'Total'),
            _divider(),
            _stat(Icons.star_rounded, AppColors.warning, '—', 'Avaliação'),
            _divider(),
            _stat(Icons.thumb_up_outlined, AppColors.success, '—',
                'Aceitação'),
          ],
        ),
      );

  Widget _stat(IconData icon, Color color, String value, String label) =>
      Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.dark)),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.grey)),
        ],
      );

  Widget _divider() =>
      Container(width: 1, height: 40, color: AppColors.greyLight);

  Widget _emptyList() => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.greyLight),
            SizedBox(height: 12),
            Text('Nenhuma corrida no histórico',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.dark)),
            SizedBox(height: 4),
            Text('As corridas concluídas aparecerão aqui.',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
