import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});
  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MyPetAppBar(showBack: false),
      body: Column(children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              const Tab(text: 'Proximos'),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Pendentes'),
                const SizedBox(width:6),
                Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:2), decoration: BoxDecoration(color: AppColors.pending, borderRadius: BorderRadius.circular(10)), child: const Text('2', style: TextStyle(color: Colors.white, fontSize:11, fontWeight: FontWeight.w700))),
              ])),
            ],
          ),
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          _AppointmentList(status: 'Confirmado', statusColor: AppColors.confirmed),
          _AppointmentList(status: 'Pendente', statusColor: AppColors.pending),
        ])),
      ]),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final String status; final Color statusColor;
  const _AppointmentList({required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom:12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(radius:26, backgroundColor: Color(0xFFD4A574), child: Icon(Icons.pets, color: Colors.white)),
            const SizedBox(width:12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Rex', style: TextStyle(fontWeight: FontWeight.w700, fontSize:15)),
              const Text('Golden Retriever - 3 anos', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)), child: Text(status, style: const TextStyle(color: Colors.white, fontSize:12, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height:12),
          _row(Icons.location_on_outlined, 'Pet Shop Amor e Carinho'),
          const SizedBox(height:4),
          _row(Icons.calendar_today_outlined, i == 0 ? '17 de marco de 2026' : '24 de marco de 2026'),
          const SizedBox(height:4),
          _row(Icons.access_time_outlined, '14:00'),
          const SizedBox(height:8),
          const Text('Valor: R\$ 50,00', style: TextStyle(fontWeight: FontWeight.w600, fontSize:14)),
        ]),
      ),
    );
  }

  static Widget _row(IconData icon, String text) => Row(
    children: [Icon(icon, size:16, color: AppColors.textSecondary), const SizedBox(width:8), Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize:13))],
  );
}
