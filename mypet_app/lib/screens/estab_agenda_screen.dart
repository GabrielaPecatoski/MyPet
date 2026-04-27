import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/establishment_provider.dart';
import '../widgets/mypet_app_bar.dart';
import 'estab_horarios_screen.dart';

class EstabAgendaScreen extends StatefulWidget {
  const EstabAgendaScreen({super.key});

  @override
  State<EstabAgendaScreen> createState() => _EstabAgendaScreenState();
}

class _EstabAgendaScreenState extends State<EstabAgendaScreen> {
  DateTime _selectedDate = DateTime.now();

  static const _weekdayShort = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _monthNames = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];

  // Semana que contém _selectedDate
  List<DateTime> get _weekDays {
    final dow = _selectedDate.weekday % 7; // 0 = domingo
    final sunday = _selectedDate.subtract(Duration(days: dow));
    return List.generate(7, (i) => sunday.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) return;

    final estabProvider = context.read<EstablishmentProvider>();
    if (estabProvider.establishment == null) {
      await estabProvider.loadByOwner(
        token: auth.token!,
        ownerId: auth.user!.id,
        ownerName: auth.user!.name,
        ownerPhone: auth.user!.phone,
      );
    }

    final estabId = estabProvider.establishmentId;
    if (estabId != null && mounted) {
      context.read<BookingProvider>().loadEstabBookings(
            token: auth.token!,
            estabId: estabId,
          );
    }
  }

  List<AppointmentModel> get _dayBookings {
    final all = context.read<BookingProvider>().bookings;
    return all
        .where((b) =>
            b.date.year == _selectedDate.year &&
            b.date.month == _selectedDate.month &&
            b.date.day == _selectedDate.day)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  bool _hasBookings(DateTime d, List<AppointmentModel> all) => all.any(
      (b) =>
          b.date.year == d.year &&
          b.date.month == d.month &&
          b.date.day == d.day);

  Future<void> _updateStatus(AppointmentModel booking, String status) async {
    final auth = context.read<AuthProvider>();
    final ok = await context.read<BookingProvider>().updateStatus(
          token: auth.token!,
          bookingId: booking.id,
          status: status,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(status == 'CONFIRMADO'
          ? 'Agendamento confirmado!'
          : 'Agendamento recusado'),
      backgroundColor:
          status == 'CONFIRMADO' ? AppColors.success : AppColors.danger,
    ));
    if (ok) setState(() {});
  }

  void _prevWeek() =>
      setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)));
  void _nextWeek() =>
      setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final estab = context.watch<EstablishmentProvider>();
    final all = booking.bookings;
    final dayBookings = _dayBookings;
    final week = _weekDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstabHorariosScreen()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.schedule, color: Colors.white),
        label: const Text('Gerenciar horários',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── Header roxo com stats ──────────────────────────────
          EstabPurpleHeader(
            pendentes: booking.pendentes.length,
            confirmados: booking.confirmados.length,
            avaliacao:
                estab.establishment?.rating.toStringAsFixed(1) ?? '—',
          ),

          // ── Calendário semanal ─────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                // Mês + ano + navegação
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _prevWeek,
                      child: const Icon(Icons.chevron_left,
                          color: AppColors.dark, size: 24),
                    ),
                    Text(
                      '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.dark),
                    ),
                    GestureDetector(
                      onTap: _nextWeek,
                      child: const Icon(Icons.chevron_right,
                          color: AppColors.dark, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dias da semana
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: week.map((date) {
                    final isSelected =
                        date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;
                    final isToday = date.year == DateTime.now().year &&
                        date.month == DateTime.now().month &&
                        date.day == DateTime.now().day;
                    final hasDots = _hasBookings(date, all);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Column(
                        children: [
                          Text(
                            _weekdayShort[date.weekday % 7],
                            style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.grey),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isToday
                                      ? AppColors.primaryLight
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : isToday
                                            ? AppColors.primary
                                            : AppColors.dark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Pontos indicando agendamentos
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              hasDots ? 3 : 1,
                              (_) => Container(
                                width: 4,
                                height: 4,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: hasDots
                                      ? (isSelected
                                          ? AppColors.primary
                                          : AppColors.grey)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Título do dia ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agendamentos (${dayBookings.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.dark),
                ),
                if (booking.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              color: AppColors.primary,
              child: dayBookings.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 60),
                      Center(
                        child: Column(children: [
                          Icon(Icons.calendar_today,
                              size: 40, color: AppColors.greyLight),
                          SizedBox(height: 10),
                          Text('Nenhum agendamento neste dia',
                              style: TextStyle(color: AppColors.grey)),
                        ]),
                      ),
                    ])
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: dayBookings.length,
                      itemBuilder: (_, i) => _ApptCard(
                          appointment: dayBookings[i],
                          onUpdateStatus: _updateStatus),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card do agendamento ──────────────────────────────────────────────
class _ApptCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Future<void> Function(AppointmentModel, String) onUpdateStatus;

  const _ApptCard(
      {required this.appointment, required this.onUpdateStatus});

  Color get _statusColor {
    switch (appointment.status) {
      case 'CONFIRMADO':
        return AppColors.success;
      case 'RECUSADO':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = appointment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horário
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            const Icon(Icons.access_time, size: 14, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(ap.time,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.grey)),
          ]),
        ),

        Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet + status badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.pets,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ap.petName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.dark)),
                        if (ap.petBreed.isNotEmpty)
                          Text(ap.petBreed,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(ap.statusLabel,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Detalhes do tutor e serviço
              if (ap.userName.isNotEmpty)
                _row(Icons.person_outline,
                    'Tutor: ${ap.userName}'),
              const SizedBox(height: 4),
              _row(Icons.content_cut_outlined, ap.serviceName),
              if (ap.price > 0) ...[
                const SizedBox(height: 4),
                _row(Icons.attach_money,
                    'R\$ ${ap.price.toStringAsFixed(2)}'),
              ],

              // Botões para pendentes
              if (ap.isPendente) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onUpdateStatus(ap, 'RECUSADO'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side:
                            const BorderSide(color: AppColors.danger),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, size: 16),
                          SizedBox(width: 4),
                          Text('Recusar',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          onUpdateStatus(ap, 'CONFIRMADO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Confirmar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: AppColors.grey),
        const SizedBox(width: 5),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.grey))),
      ]);
}
