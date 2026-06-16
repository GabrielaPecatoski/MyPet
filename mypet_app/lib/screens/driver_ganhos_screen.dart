import 'package:flutter/material.dart';
import '../core/colors.dart';

class DriverGanhosScreen extends StatelessWidget {
  const DriverGanhosScreen({super.key});

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
            _earningsCard(),
            const SizedBox(height: 16),
            _pixCard(),
            const SizedBox(height: 20),
            _emptyRecentRides(),
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
            child: const Icon(Icons.attach_money,
                color: AppColors.driver, size: 20),
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
              Text('GANHOS',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark)),
            ],
          ),
        ],
      );

  Widget _earningsCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEA580C), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Disponível para saque',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            const Text('R\$ 0,00',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _miniStat('Esta semana', 'R\$ 0,00'),
                const SizedBox(width: 24),
                _miniStat('Corridas', '0'),
              ],
            ),
          ],
        ),
      );

  Widget _miniStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      );

  Widget _pixCard() => Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pix,
                  color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transferir via PIX',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.dark)),
                  Text('Configure sua chave PIX para saques',
                      style: TextStyle(fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.greyLight),
          ],
        ),
      );

  Widget _emptyRecentRides() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Corridas recentes',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.dark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
            ),
            child: const Center(
              child: Text('Nenhuma corrida realizada ainda.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey)),
            ),
          ),
        ],
      );
}
