import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/vet_profile_provider.dart';
import '../widgets/attendance_photos.dart';

class VetAgendaScreen extends StatefulWidget {
  const VetAgendaScreen({super.key});

  @override
  State<VetAgendaScreen> createState() => _VetAgendaScreenState();
}

class _VetAgendaScreenState extends State<VetAgendaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final DateTime _today = DateTime.now();

  List<AppointmentModel> _bookings = [];
  bool _loading = true;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final vetVm = context.read<VetProfileProvider>();
    final token = auth.token;
    if (token == null || auth.user?.cpf == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (vetVm.vet == null) {
      await vetVm.load(token: token, cpf: auth.user!.cpf!);
    }
    final vetId = vetVm.vet?.id;
    if (vetId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final data = await vetVm.fetchBookings(token: token, vetId: vetId);
      if (mounted) setState(() => _bookings = data);
    } catch (_) {
      if (mounted) setState(() => _bookings = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _managePhotos(AppointmentModel booking) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final result = await showAttendancePhotosSheet(
      context,
      token: token,
      bookingId: booking.id,
      initial: booking.attendancePhotos,
      accent: AppColors.vet,
    );
    if (result != null && mounted) {
      await _load();
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<AppointmentModel> get _hoje =>
      _bookings.where((b) => _sameDay(b.date, _today)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  List<AppointmentModel> get _amanha {
    final t = _today.add(const Duration(days: 1));
    return _bookings.where((b) => _sameDay(b.date, t)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<AppointmentModel> get _semana {
    final fim = _today.add(const Duration(days: 7));
    return _bookings
        .where((b) => b.date.isAfter(_today.subtract(const Duration(days: 1))) && b.date.isBefore(fim))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
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
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : TabBarView(
                    controller: _tab,
                    children: [
                      _dayList(_hoje, 'Nenhuma consulta hoje.'),
                      _dayList(_amanha, 'Nenhuma consulta amanhã.'),
                      _dayList(_semana, 'Nenhuma consulta esta semana.'),
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
              _statChip('${_hoje.length}', 'Consultas', AppColors.vet),
              const SizedBox(width: 8),
              _statChip('${_hoje.where((b) => b.status == 'CONFIRMADO').length}',
                  'Confirmadas', AppColors.success),
              const SizedBox(width: 8),
              _statChip('${_hoje.where((b) => b.status == 'PENDENTE').length}',
                  'Pendentes', AppColors.warning),
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

  Widget _dayList(List<AppointmentModel> items, String emptyLabel) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: _green,
        child: ListView(children: [
          const SizedBox(height: 60),
          _EmptyTab(label: emptyLabel),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) =>
            _VetBookingCard(ap: items[i], onManagePhotos: _managePhotos),
      ),
    );
  }
}

class _VetBookingCard extends StatelessWidget {
  final AppointmentModel ap;
  final Future<void> Function(AppointmentModel) onManagePhotos;
  const _VetBookingCard({required this.ap, required this.onManagePhotos});

  static const _green = Color(0xFF16A34A);

  Color get _statusColor {
    switch (ap.status) {
      case 'CONFIRMADO': return AppColors.success;
      case 'RECUSADO':
      case 'CANCELADO': return AppColors.danger;
      case 'CONCLUIDO': return AppColors.vet;
      default: return AppColors.warning;
    }
  }

  String get _statusLabel {
    switch (ap.status) {
      case 'CONFIRMADO': return 'Confirmado';
      case 'PENDENTE': return 'Aguardando confirmação';
      case 'RECUSADO': return 'Recusado';
      case 'CANCELADO': return 'Cancelado';
      case 'CONCLUIDO': return 'Concluído';
      default: return ap.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0x1416A34A),
              child: Icon(Icons.pets, color: _green, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ap.petName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
                Text(ap.serviceName, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_statusLabel,
                  style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          _row(Icons.person_outline, ap.userName.isNotEmpty ? ap.userName : 'Tutor'),
          const SizedBox(height: 4),
          _row(Icons.access_time,
              '${ap.date.day.toString().padLeft(2, '0')}/${ap.date.month.toString().padLeft(2, '0')}  ${ap.time}'),
          if (ap.establishmentName.isNotEmpty) ...[
            const SizedBox(height: 4),
            _row(Icons.store_outlined, ap.establishmentName),
          ],
          if (ap.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            _row(Icons.location_on_outlined, ap.address),
          ],
          if (ap.price > 0) ...[
            const SizedBox(height: 4),
            _row(Icons.attach_money, 'R\$ ${ap.price.toStringAsFixed(2)}'),
          ],
          if (ap.isConfirmado ||
              ap.isACaminho ||
              ap.effectiveStatus == 'CONCLUIDO') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onManagePhotos(ap),
                icon: const Icon(Icons.photo_camera_outlined, size: 16),
                label: Text(
                    ap.attendancePhotos.isEmpty
                        ? 'Fotos do atendimento'
                        : 'Fotos do atendimento (${ap.attendancePhotos.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.vet,
                  side: const BorderSide(color: AppColors.vet),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
        Icon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.grey))),
      ]);
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
