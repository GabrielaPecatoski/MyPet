import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/review_service.dart';
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

  List<AppointmentModel> _dayBookingsFor(List<AppointmentModel> all) {
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
    final dayBookings = _dayBookingsFor(all);
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: _statusColor.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra colorida lateral
                  Container(width: 5, color: _statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                                              fontSize: 12,
                                              color: AppColors.grey)),
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
                            _row(Icons.person_outline, 'Tutor: ${ap.userName}'),
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
                                  onPressed: () =>
                                      onUpdateStatus(ap, 'RECUSADO'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(
                                        color: AppColors.danger),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
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

                          // Botão Concluir para confirmados
                          if (ap.isConfirmado) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await onUpdateStatus(ap, 'CONCLUIDO');
                                  if (context.mounted) {
                                    _showAvaliarClienteDialog(context, ap);
                                  }
                                },
                                icon: const Icon(Icons.check_circle,
                                    size: 16, color: Colors.white),
                                label: const Text('Concluir serviço',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                style: const TextStyle(fontSize: 12, color: AppColors.grey))),
      ]);

  Future<void> _showAvaliarClienteDialog(BuildContext context, AppointmentModel ap) async {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();
    final estabProvider = context.read<EstablishmentProvider>();
    final auth = context.read<AuthProvider>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.star_outline, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Avaliar ${ap.userName.isNotEmpty ? ap.userName : "Cliente"}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                        fontSize: 15)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Como foi o comportamento do cliente?',
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () =>
                        setDialogState(() => selectedRating = star),
                    icon: Icon(
                      star <= selectedRating ? Icons.star : Icons.star_border,
                      color: star <= selectedRating
                          ? const Color(0xFFFFC107)
                          : AppColors.grey,
                      size: 32,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  );
                }),
              ),
              const SizedBox(height: 12),
              const Text('Observação (opcional)',
                  style: TextStyle(fontSize: 13, color: AppColors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  hintText: 'Ex: cliente pontual, pet bem comportado...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.greyLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.greyLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Esta avaliação é visível apenas para outros estabelecimentos e para o admin.',
                        style: TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Pular',
                        style: TextStyle(color: AppColors.grey)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: selectedRating == 0
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            try {
                              await ReviewService.submitClientReview(
                                establishmentId:
                                    estabProvider.establishmentId ?? '',
                                establishmentName:
                                    estabProvider.establishment?.name ?? '',
                                clientId: ap.userId,
                                clientName: ap.userName,
                                bookingId: ap.id,
                                rating: selectedRating,
                                comment: commentCtrl.text.trim().isEmpty
                                    ? null
                                    : commentCtrl.text.trim(),
                                token: auth.token,
                              );
                            } catch (_) {}
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Avaliação enviada!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.greyLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Enviar',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    commentCtrl.dispose();
  }
}
