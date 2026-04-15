import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/mypet_app_bar.dart';

class EstabAgendaScreen extends StatefulWidget {
  const EstabAgendaScreen({super.key});
  @override
  State<EstabAgendaScreen> createState() => _EstabAgendaScreenState();
}

class _EstabAgendaScreenState extends State<EstabAgendaScreen> {
  DateTime _selectedDate = DateTime(2026, 3, 3);
  DateTime _currentMonth = DateTime(2026, 3, 1);

  final _appointments = {
    DateTime(2026, 3, 3): [
      {'hora': '10:00', 'pet': 'Rex', 'raca': 'Golden Retriever', 'tutor': 'João Silva', 'servico': 'Banho e Tosa', 'telefone': '(11) 99999-9999', 'status': 'CONFIRMADO'},
      {'hora': '14:30', 'pet': 'Luna', 'raca': 'Siamês', 'tutor': 'João Silva', 'servico': 'Banho', 'telefone': '(11) 99999-9999', 'status': 'PENDENTE'},
    ],
    DateTime(2026, 3, 18): [
      {'hora': '09:00', 'pet': 'Mel', 'raca': 'Poodle', 'tutor': 'Maria Costa', 'servico': 'Tosa', 'telefone': '(11) 98888-7777', 'status': 'CONFIRMADO'},
    ],
    DateTime(2026, 3, 20): [
      {'hora': '11:00', 'pet': 'Thor', 'raca': 'Labrador', 'tutor': 'Carlos Souza', 'servico': 'Banho', 'telefone': '(11) 97777-6666', 'status': 'CONFIRMADO'},
      {'hora': '15:00', 'pet': 'Nina', 'raca': 'Yorkshire', 'tutor': 'Ana Lima', 'servico': 'Banho e Tosa', 'telefone': '(11) 96666-5555', 'status': 'PENDENTE'},
    ],
  };

  List<Map<String, String>> get _selectedDayAppts {
    for (final entry in _appointments.entries) {
      if (entry.key.year == _selectedDate.year &&
          entry.key.month == _selectedDate.month &&
          entry.key.day == _selectedDate.day) {
        return List<Map<String, String>>.from(entry.value);
      }
    }
    return [];
  }

  bool _hasAppointments(DateTime date) {
    for (final key in _appointments.keys) {
      if (key.year == date.year && key.month == date.month && key.day == date.day) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MypetAppBar(
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.person, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header roxo com stats ────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _topStat('Pendentes', '2', AppColors.warning),
                const SizedBox(width: 8),
                _topStat('Confirmados', '2', AppColors.success),
                const SizedBox(width: 8),
                _topStat('Avaliação', '4.6', const Color(0xFFFFC107)),
              ],
            ),
          ),
          // ── Calendário ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Cabeçalho do mês
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _currentMonth =
                          DateTime(_currentMonth.year, _currentMonth.month - 1)),
                    ),
                    Text(
                      _formatMonth(_currentMonth),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.dark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() => _currentMonth =
                          DateTime(_currentMonth.year, _currentMonth.month + 1)),
                    ),
                  ],
                ),
                // Dias da semana
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['dom', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb']
                      .map((d) => SizedBox(
                            width: 36,
                            child: Text(d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.grey)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                // Grade de dias
                _buildCalendarGrid(),
              ],
            ),
          ),
          // ── Agendamentos do dia ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text(
                  'Agendamentos (${_selectedDayAppts.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.dark),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDayAppts.isEmpty
                ? const Center(
                    child: Text('Nenhum agendamento neste dia',
                        style: TextStyle(color: AppColors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _selectedDayAppts.length,
                    itemBuilder: (ctx, i) {
                      final ap = _selectedDayAppts[i];
                      return _apptCard(ap);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // domingo = 0

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final hasAppts = _hasAppointments(date);
      cells.add(GestureDetector(
        onTap: () => setState(() => _selectedDate = date),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('$day',
                  style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.dark,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
              if (hasAppts && !isSelected)
                Positioned(
                  bottom: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 4, height: 4,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: cells,
    );
  }

  Widget _apptCard(Map<String, String> ap) {
    final isConfirmed = ap['status'] == 'CONFIRMADO';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(ap['hora']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.pets,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ap['pet']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(ap['raca']!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConfirmed
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(ap['status']!,
                        style: TextStyle(
                            color: isConfirmed
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _row(Icons.person_outline, 'Tutor: ${ap['tutor']}'),
              _row(Icons.content_cut, ap['servico']!),
              _row(Icons.phone_outlined, ap['telefone']!),
              if (!isConfirmed) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Recusar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Confirmar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _topStat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      );

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          ],
        ),
      );

  String _formatMonth(DateTime d) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}
