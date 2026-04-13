import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  final _notifs = const [
    {'title': 'Agendamento Confirmado', 'body': 'Seu banho e tosa foi confirmado para 15/03/2026 as 14:00', 'time': '2 horas', 'color': 0xFF4CAF50},
    {'title': 'Lembrete de Consulta', 'body': 'Nao esqueca da consulta veterinaria amanha as 10:00', 'time': '5 horas', 'color': 0xFF7048E8},
    {'title': 'Lembrete de Consulta', 'body': 'Nao esqueca da consulta veterinaria amanha as 10:00', 'time': '7 dias', 'color': 0xFFFF9800},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MyPetAppBar(),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifs.length,
        separatorBuilder: (_, ignore) => const SizedBox(height:10),
        itemBuilder: (_, i) {
          final n = _notifs[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width:42, height:42, decoration: BoxDecoration(color: Color(n['color'] as int).withAlpha(31), shape: BoxShape.circle), child: Icon(Icons.notifications_outlined, color: Color(n['color'] as int), size:22)),
              const SizedBox(width:12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:14)),
                const SizedBox(height:4),
                Text(n['body'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize:13)),
                const SizedBox(height:4),
                Text(n['time'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize:12)),
              ])),
            ]),
          );
        },
      ),
    );
  }
}
