import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/establishment_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/attendance_photos.dart';
import '../widgets/mypet_app_bar.dart';

class EstabAgendaScreen extends StatefulWidget {
  const EstabAgendaScreen({super.key});

  @override
  State<EstabAgendaScreen> createState() => _EstabAgendaScreenState();
}

class _EstabAgendaScreenState extends State<EstabAgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _bookingsEstabId;

  static const _weekdayShort = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _monthNames = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];

  List<DateTime> get _weekDays {
    final dow = _selectedDate.weekday % 7;
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
      _bookingsEstabId = estabId;
      context.read<BookingProvider>().loadEstabBookings(
            token: auth.token!,
            estabId: estabId,
          );
    }
    // Se o estabelecimento ainda não está disponível (load lento), o build
    // dispara o carregamento reativamente assim que o id aparecer.
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
    String msg;
    Color color;
    if (!ok) {
      msg = 'Erro ao atualizar agendamento';
      color = AppColors.danger;
    } else {
      switch (status) {
        case 'CONFIRMADO':
          msg = 'Agendamento confirmado!';
          color = AppColors.success;
        case 'CONCLUIDO':
          msg = 'Serviço concluído! Pagamento liberado.';
          color = AppColors.estab;
        default:
          msg = 'Agendamento recusado. Valor estornado ao cliente.';
          color = AppColors.danger;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  Future<void> _managePhotos(AppointmentModel booking) async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    final result = await showAttendancePhotosSheet(
      context,
      token: auth.token!,
      bookingId: booking.id,
      initial: booking.attendancePhotos,
      accent: AppColors.estab,
    );
    if (result != null && mounted) {
      await _load();
    }
  }

  void _prevWeek() =>
      setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)));
  void _nextWeek() =>
      setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final estab = context.watch<EstablishmentProvider>();

    // Carrega os agendamentos assim que o estabelecimento ficar disponível
    // (o load inicial pode correr antes do id existir, sob carga/lentidão).
    final estabId = estab.establishmentId;
    final token = context.read<AuthProvider>().token;
    if (estabId != null && token != null && _bookingsEstabId != estabId) {
      _bookingsEstabId = estabId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context
              .read<BookingProvider>()
              .loadEstabBookings(token: token, estabId: estabId);
        }
      });
    }

    final all = booking.bookings;
    final dayBookings = _dayBookingsFor(all);
    final week = _weekDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/estab-horarios'),
        backgroundColor: AppColors.estab,
        icon: const Icon(Icons.schedule, color: Colors.white),
        label: const Text('Gerenciar horários',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          EstabPurpleHeader(
            pendentes: booking.pendentes.length,
            confirmados: booking.confirmados.length,
            avaliacao:
                estab.establishment?.rating.toStringAsFixed(1) ?? '—',
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
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
                                    ? AppColors.estab
                                    : AppColors.grey),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.estab
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
                                            ? AppColors.estab
                                            : AppColors.dark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                                          ? AppColors.estab
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
                        strokeWidth: 2, color: AppColors.estab),
                  ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              color: AppColors.estab,
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
                          onUpdateStatus: _updateStatus,
                          onManagePhotos: _managePhotos),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApptCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Future<void> Function(AppointmentModel, String) onUpdateStatus;
  final Future<void> Function(AppointmentModel) onManagePhotos;

  const _ApptCard(
      {required this.appointment,
      required this.onUpdateStatus,
      required this.onManagePhotos});

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

        GestureDetector(
          onTap: () => _showDetail(context),
          child: Container(
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
                  Container(width: 5, color: _statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryLight,
                                child: const Icon(Icons.pets,
                                    color: AppColors.estab, size: 24),
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

                          if (ap.userName.isNotEmpty)
                            _row(Icons.person_outline, 'Tutor: ${ap.userName}'),
                          const SizedBox(height: 4),
                          _row(Icons.content_cut_outlined, ap.serviceName),
                          if (ap.price > 0) ...[
                            const SizedBox(height: 4),
                            _row(Icons.attach_money,
                                'R\$ ${ap.price.toStringAsFixed(2)}'),
                          ],
                          if (ap.isRetido) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_outlined, size: 13, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text('Pagamento confirmado',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],

                          if (ap.isPendente && (ap.isPago || ap.priceVariable)) ...[
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

                          if (ap.isConfirmado || ap.isACaminho ||
                              ap.effectiveStatus == 'CONCLUIDO') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => onManagePhotos(ap),
                                icon: const Icon(Icons.photo_camera_outlined,
                                    size: 16),
                                label: Text(
                                    ap.attendancePhotos.isEmpty
                                        ? 'Fotos do atendimento'
                                        : 'Fotos do atendimento (${ap.attendancePhotos.length})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.estab,
                                  side: const BorderSide(color: AppColors.estab),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],

                          if (ap.isConfirmado) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await onUpdateStatus(ap, 'CONCLUIDO');
                                  if (context.mounted) {
                                    await onManagePhotos(ap);
                                  }
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
                                  backgroundColor: AppColors.estab,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final auth = context.read<AuthProvider>();
                                  final chat = context.read<ChatProvider>();
                                  if (auth.token == null) return;
                                  try {
                                    final conv =
                                        await chat.openOrCreateConversation(
                                      bookingId: ap.id,
                                      clientId: ap.userId,
                                      establishmentId: ap.establishmentId,
                                      token: auth.token!,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.pushNamed(context, '/chat',
                                        arguments: conv);
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Não foi possível abrir o chat'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.chat_bubble_outline,
                                    size: 16, color: AppColors.primary),
                                label: const Text('Responder cliente',
                                    style:
                                        TextStyle(color: AppColors.primary)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.primary),
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

  void _showDetail(BuildContext context) {
    final ap = appointment;
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    final dateLabel =
        '${ap.date.day} de ${months[ap.date.month - 1]} de ${ap.date.year} • ${ap.time}';
    final canPhotos = ap.isConfirmado ||
        ap.isACaminho ||
        ap.effectiveStatus == 'CONCLUIDO';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.pets, color: AppColors.estab, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ap.petName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.dark)),
                      if (ap.petBreed.isNotEmpty)
                        Text(
                          '${ap.petBreed}${ap.petAge > 0 ? ' • ${ap.petAge} anos' : ''}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.grey),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
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
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.greyLight),
            const SizedBox(height: 16),
            if (ap.emAtendimento) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record,
                        size: 12, color: AppColors.success),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Em atendimento agora — adicione fotos para o tutor acompanhar.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (ap.userName.isNotEmpty)
              _detailRow(Icons.person_outline, 'Tutor: ${ap.userName}'),
            _detailRow(Icons.content_cut_outlined, ap.serviceName),
            _detailRow(Icons.calendar_today_outlined, dateLabel),
            if (ap.price > 0)
              _detailRow(Icons.attach_money, 'R\$ ${ap.price.toStringAsFixed(2)}'),
            if (ap.isRetido)
              _detailRow(Icons.verified_outlined, 'Pagamento confirmado (retido)'),
            if (ap.driverName != null && ap.driverName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    PhotoBox(
                      url: ap.driverPhotoUrl,
                      size: 34,
                      radius: 17,
                      background: AppColors.primaryLight,
                      fallback: const Icon(Icons.local_shipping_outlined,
                          color: AppColors.estab, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Motorista: ${ap.driverName}',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.dark)),
                    ),
                  ],
                ),
              ),
            if (ap.attendancePhotos.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Fotos do atendimento (${ap.attendancePhotos.length})',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark)),
              const SizedBox(height: 8),
              AttendancePhotosGrid(photos: ap.attendancePhotos),
            ],
            if (canPhotos) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    onManagePhotos(ap);
                  },
                  icon: const Icon(Icons.photo_camera_outlined,
                      size: 16, color: Colors.white),
                  label: Text(
                      ap.attendancePhotos.isEmpty
                          ? 'Adicionar fotos do atendimento'
                          : 'Gerenciar fotos (${ap.attendancePhotos.length})',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.estab,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.grey),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.dark))),
          ],
        ),
      );

  Future<void> _showAvaliarClienteDialog(BuildContext context, AppointmentModel ap) async {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();

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
                    borderSide: const BorderSide(color: AppColors.estab),
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
                    Icon(Icons.info_outline, size: 14, color: AppColors.estab),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Esta avaliação é visível apenas para outros estabelecimentos e para o admin.',
                        style: TextStyle(fontSize: 11, color: AppColors.estab),
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
                      backgroundColor: AppColors.estab,
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
