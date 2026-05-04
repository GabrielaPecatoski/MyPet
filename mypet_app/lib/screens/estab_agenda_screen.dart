import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/mypet_app_bar.dart';

class EstabAgendaScreen extends StatefulWidget {
  const EstabAgendaScreen({super.key});
  @override
  State<EstabAgendaScreen> createState() => _EstabAgendaScreenState();
}

class _EstabAgendaScreenState extends State<EstabAgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<Map<String, dynamic>> _allBookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final estabData = await ApiService.get(
        '/establishments/owner/$userId',
        token: token,
      );
      final list = estabData as List<dynamic>;
      if (list.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final estabId = (list.first as Map<String, dynamic>)['id'] as String;
      final bookingData = await ApiService.get(
        '/bookings/establishment/$estabId',
        token: token,
      );
      if (mounted) {
        setState(() {
          _allBookings = (bookingData as List<dynamic>)
              .map((b) => b as Map<String, dynamic>)
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _bookingsForDate(DateTime date) {
    return _allBookings.where((b) {
      final iso = b['scheduledAt'] as String?;
      if (iso == null) return false;
      try {
        final dt = DateTime.parse(iso).toLocal();
        return dt.year == date.year &&
            dt.month == date.month &&
            dt.day == date.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  bool _hasBookings(DateTime date) => _bookingsForDate(date).isNotEmpty;

  List<Map<String, dynamic>> get _selectedDayBookings =>
      _bookingsForDate(_selectedDate);

  int get _pendentes =>
      _allBookings.where((b) => b['status'] == 'PENDENTE').length;
  int get _confirmados =>
      _allBookings.where((b) => b['status'] == 'CONFIRMADO').length;

  Future<void> _updateStatus(String bookingId, String status) async {
    final token = context.read<AuthProvider>().token;
    try {
      await ApiService.patch(
        '/bookings/$bookingId/status',
        {'status': status},
        token: token,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'CONFIRMADO'
              ? 'Agendamento confirmado!'
              : 'Agendamento recusado.'),
          backgroundColor:
              status == 'CONFIRMADO' ? AppColors.success : AppColors.danger,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao atualizar status'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  String _formatHour(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      _topStat('Pendentes', '$_pendentes', AppColors.warning),
                      const SizedBox(width: 8),
                      _topStat(
                          'Confirmados', '$_confirmados', AppColors.success),
                      const SizedBox(width: 8),
                      _topStat('Total',
                          '${_allBookings.length}', Colors.white),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => setState(() => _currentMonth =
                                DateTime(_currentMonth.year,
                                    _currentMonth.month - 1)),
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
                                DateTime(_currentMonth.year,
                                    _currentMonth.month + 1)),
                          ),
                        ],
                      ),
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
                      _buildCalendarGrid(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Agendamentos (${_selectedDayBookings.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark),
                      ),
                      TextButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh,
                            size: 16, color: AppColors.primary),
                        label: const Text('Atualizar',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedDayBookings.isEmpty
                      ? const Center(
                          child: Text('Nenhum agendamento neste dia',
                              style: TextStyle(color: AppColors.grey)))
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _selectedDayBookings.length,
                          itemBuilder: (ctx, i) =>
                              _apptCard(_selectedDayBookings[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date =
          DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final hasAppts = _hasBookings(date);
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal)),
              if (hasAppts && !isSelected)
                Positioned(
                  bottom: 3,
                  child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary)),
                ),
            ],
          ),
        ),
      ));
    }

    return Wrap(spacing: 4, runSpacing: 2, children: cells);
  }

  Widget _apptCard(Map<String, dynamic> b) {
    final status = b['status'] as String? ?? 'PENDENTE';
    final isConfirmed = status == 'CONFIRMADO';
    final isPending = status == 'PENDENTE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(_formatHour(b['scheduledAt'] as String?),
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
                    child: Text(b['petName'] as String? ?? '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConfirmed
                          ? AppColors.success.withValues(alpha: 0.12)
                          : isPending
                              ? AppColors.warning.withValues(alpha: 0.12)
                              : AppColors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            color: isConfirmed
                                ? AppColors.success
                                : isPending
                                    ? AppColors.warning
                                    : AppColors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _row(Icons.person_outline,
                  'Tutor: ${b['userName'] as String? ?? '—'}'),
              _row(Icons.content_cut,
                  b['serviceName'] as String? ?? '—'),
              if (b['price'] != null)
                _row(Icons.attach_money,
                    'R\$ ${(b['price'] as num).toStringAsFixed(2)}'),
              if (isPending) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _updateStatus(b['id'] as String, 'RECUSADO'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side:
                              const BorderSide(color: AppColors.danger),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Recusar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _updateStatus(b['id'] as String, 'CONFIRMADO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
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
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.grey))),
          ],
        ),
      );

  String _formatMonth(DateTime d) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}
