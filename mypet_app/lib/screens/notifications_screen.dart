import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final _notifications = [
    _NotifItem(
      title: 'Agendamento Confirmado',
      body: 'Seu banho e tosa foi confirmado para 15/03/2026 às 14:00',
      time: '2 horas',
      icon: Icons.check_circle,
      color: AppColors.success,
    ),
    _NotifItem(
      title: 'Lembrete de Consulta',
      body: 'Não esqueça da consulta veterinária amanhã às 10:00',
      time: '5 horas',
      icon: Icons.notifications,
      color: AppColors.primary,
    ),
    _NotifItem(
      title: 'Lembrete de Consulta',
      body: 'Não esqueça da consulta veterinária amanhã às 10:00',
      time: '7 dias',
      icon: Icons.notifications,
      color: AppColors.warning,
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
      body: _notifications.isEmpty
          ? const Center(
              child: Text('Nenhuma notificação',
                  style: TextStyle(color: AppColors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (ctx, i) {
                final n = _notifications[i];
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: n.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(n.icon, color: n.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.dark)),
                            const SizedBox(height: 4),
                            Text(n.body,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.grey)),
                            const SizedBox(height: 6),
                            Text(n.time,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _NotifItem {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  const _NotifItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
  });
}
