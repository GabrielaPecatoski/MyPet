import 'package:flutter/material.dart';
import '../core/colors.dart';

class VetAgendaScreen extends StatefulWidget {
  const VetAgendaScreen({super.key});

  @override
  State<VetAgendaScreen> createState() => _VetAgendaScreenState();
}

class _VetAgendaScreenState extends State<VetAgendaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final DateTime _today = DateTime.now();

  static const _dayLabels = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  static const _green = Color(0xFF16A34A);
  static const _greenDark = Color(0xFF0F7A35);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _topHeader(top),
          _tabBar(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _EmptyTab(label: 'Nenhuma consulta hoje.'),
                _EmptyTab(label: 'Nenhuma consulta amanhã.'),
                _EmptyTab(label: 'Nenhuma consulta esta semana.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader(double top) {
    final d = _today;
    final dayLabel =
        '${_dayLabels[d.weekday % 7]}, ${d.day} de ${_monthNames[d.month - 1]}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenDark, _green],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MY PET · VETERINÁRIO',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.8)),
                  Text(dayLabel,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Agenda',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            children: [
              _statChip('0', 'Consultas', AppColors.vet),
              const SizedBox(width: 8),
              _statChip('0', 'Confirmadas', AppColors.success),
              const SizedBox(width: 8),
              _statChip('0', 'Pendentes', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _tabBar() => Container(
        color: Colors.white,
        child: TabBar(
          controller: _tab,
          labelColor: _green,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: _green,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Hoje'),
            Tab(text: 'Amanhã'),
            Tab(text: 'Semana'),
          ],
        ),
      );
}

class _EmptyTab extends StatelessWidget {
  final String label;
  const _EmptyTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.event_available_outlined,
                  size: 32, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
