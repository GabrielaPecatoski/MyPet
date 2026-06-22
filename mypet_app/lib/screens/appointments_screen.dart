import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_reviews_provider.dart';
import '../repositories/user_reviews_repository.dart';
import '../widgets/app_image.dart';
import '../widgets/attendance_photos.dart';
import '../widgets/mypet_app_bar.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserReviewsProvider(UserReviewsRepository()),
      child: const _AgendaView(),
    );
  }
}

class _AgendaView extends StatefulWidget {
  const _AgendaView();

  @override
  State<_AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<_AgendaView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) return;
    context.read<BookingProvider>().loadUserBookings(
          token: auth.token!,
          userId: auth.user!.id,
        );
    context.read<UserReviewsProvider>().loadReviewed(token: auth.token!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cancel(AppointmentModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar agendamento?'),
        content: Text(
            'Deseja cancelar ${booking.serviceName} com ${booking.petName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Não')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, elevation: 0),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = await context
        .read<BookingProvider>()
        .cancelBooking(token: auth.token!, bookingId: booking.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Agendamento cancelado'
          : (context.read<BookingProvider>().error ?? 'Erro')),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final reviews = context.watch<UserReviewsProvider>();
    final proximos = booking.ativos;
    final historico = booking.historico;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.grey,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Próximos'),
                      if (booking.pendentes.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${booking.pendentes.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Histórico'),
              ],
            ),
          ),

          if (booking.isLoading)
            const Expanded(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)))
          else if (booking.error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: AppColors.greyLight),
                      const SizedBox(height: 12),
                      Text(
                        booking.error!,
                        style: const TextStyle(color: AppColors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _load(),
                color: AppColors.primary,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BookingList(
                        appointments: proximos,
                        onCancel: _cancel,
                        reviewedBookingIds: reviews.reviewedBookingIds,
                        onExpired: _load),
                    _BookingList(
                        appointments: historico,
                        onCancel: _cancel,
                        isHistory: true,
                        reviewedBookingIds: reviews.reviewedBookingIds),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final Future<void> Function(AppointmentModel) onCancel;
  final bool isHistory;
  final Set<String> reviewedBookingIds;
  final VoidCallback? onExpired;

  const _BookingList({
    required this.appointments,
    required this.onCancel,
    required this.reviewedBookingIds,
    this.isHistory = false,
    this.onExpired,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.calendar_today,
                  size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
                isHistory ? 'Nenhum histórico' : 'Nenhum agendamento',
                style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                isHistory
                    ? 'Agendamentos concluídos ou cancelados aparecerão aqui'
                    : 'Agende um serviço e ele aparecerá aqui',
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: appointments.length,
      itemBuilder: (_, i) => _BookingCard(
        appointment: appointments[i],
        onCancel: onCancel,
        isReviewed: reviewedBookingIds.contains(appointments[i].id),
        onExpired: onExpired,
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final AppointmentModel appointment;
  final Future<void> Function(AppointmentModel) onCancel;
  final bool isReviewed;
  final VoidCallback? onExpired;

  const _BookingCard({
    required this.appointment,
    required this.onCancel,
    required this.isReviewed,
    this.onExpired,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_BookingCard old) {
    super.didUpdateWidget(old);
    if (old.appointment.id != widget.appointment.id ||
        old.appointment.status != widget.appointment.status) {
      _timer?.cancel();
      _startTimer();
    }
  }

  void _startTimer() {
    final ap = widget.appointment;
    if (!ap.isAguardandoPagamento || ap.expiresAt == null) return;
    _remaining = ap.expiresAt!.difference(DateTime.now());
    if (_remaining.isNegative) {
      widget.onExpired?.call();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final r = widget.appointment.expiresAt!.difference(DateTime.now());
      if (r.isNegative) {
        _timer?.cancel();
        widget.onExpired?.call();
      } else {
        setState(() => _remaining = r);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownLabel {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _statusColor(AppointmentModel ap) {
    switch (ap.status) {
      case 'AGUARDANDO_PAGAMENTO': return AppColors.primary;
      case 'CONFIRMADO':           return AppColors.success;
      case 'PENDENTE':             return AppColors.warning;
      case 'CANCELADO':
      case 'RECUSADO':             return AppColors.danger;
      case 'CONCLUIDO':            return AppColors.grey;
      default:                     return AppColors.grey;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${d.day} de ${months[d.month - 1]} de ${d.year}';
  }

  void _showAvaliarDialog(BuildContext context) {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();
    final ap = widget.appointment;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Avaliar Estabelecimento',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ap.establishmentName,
                  style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              const Text('Como foi sua experiência?',
                  style: TextStyle(color: AppColors.dark, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => selectedRating = star),
                    icon: Icon(
                      star <= selectedRating ? Icons.star : Icons.star_border,
                      color: star <= selectedRating ? const Color(0xFFFFC107) : AppColors.grey,
                      size: 34,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  );
                }),
              ),
              const SizedBox(height: 14),
              const Text('Deixe seu comentário (opcional)',
                  style: TextStyle(fontSize: 13, color: AppColors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.greyLight)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.greyLight)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedRating == 0
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final auth = context.read<AuthProvider>();
                        await context.read<UserReviewsProvider>().submitReview(
                              establishmentId: ap.establishmentId,
                              bookingId: ap.id,
                              rating: selectedRating,
                              comment: commentCtrl.text.trim().isEmpty
                                  ? null
                                  : commentCtrl.text.trim(),
                              token: auth.token ?? '',
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Avaliação enviada!'), backgroundColor: AppColors.success),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.greyLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Enviar Avaliação',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = widget.appointment;
    final isConcluido = ap.status == 'CONCLUIDO';
    final color = _statusColor(ap);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            Navigator.pushNamed(context, '/agendamento-detalhe', arguments: ap),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ap.isAguardandoPagamento)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: const Border(bottom: BorderSide(color: AppColors.greyLight)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pague em $_countdownLabel para confirmar',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: appImageProvider(ap.petPhotoUrl),
                      child: (ap.petPhotoUrl == null || ap.petPhotoUrl!.isEmpty)
                          ? const Icon(Icons.pets, color: AppColors.primary, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ap.petName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.dark)),
                          if (ap.petBreed.isNotEmpty)
                            Text(
                              '${ap.petBreed}${ap.petAge > 0 ? ' • ${ap.petAge} anos' : ''}',
                              style: const TextStyle(fontSize: 13, color: AppColors.grey),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(ap.statusLabel,
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.greyLight),
                const SizedBox(height: 12),

                _row(Icons.location_on_outlined, ap.establishmentName),
                const SizedBox(height: 6),
                _row(Icons.calendar_today_outlined, _formatDate(ap.date)),
                const SizedBox(height: 6),
                _row(Icons.access_time_outlined, ap.time),

                if (ap.driverName != null && ap.driverName!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        PhotoBox(
                          url: ap.driverPhotoUrl,
                          size: 38,
                          radius: 19,
                          background: Colors.white,
                          fallback: const Icon(Icons.local_shipping_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Motorista do transporte',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.grey)),
                              Text(ap.driverName!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (ap.attendancePhotos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.photo_camera_outlined,
                          size: 15, color: AppColors.grey),
                      const SizedBox(width: 6),
                      Text('Fotos do atendimento (${ap.attendancePhotos.length})',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AttendancePhotosGrid(photos: ap.attendancePhotos),
                ],

                if (ap.price > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Valor: R\$ ${ap.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                      if (ap.pagamentoLabel != null) ...[
                        const SizedBox(width: 8),
                        _PagamentoChip(label: ap.pagamentoLabel!, estornado: ap.isEstornado, capturado: ap.isCapturado),
                      ],
                    ],
                  ),
                ],

                if (ap.isRetido && (ap.isPendente || ap.isConfirmado)) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'O valor está retido e só será repassado ao estabelecimento após a conclusão do serviço.',
                    style: TextStyle(fontSize: 11, color: AppColors.grey),
                  ),
                ],

                if (ap.isAguardandoPagamento) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/pagamento-agendamento', arguments: ap),
                      icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                      label: const Text('Pagar Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],

                if (ap.isConfirmado) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/tracking', arguments: ap),
                      icon: const Icon(Icons.location_on_outlined, size: 16, color: Colors.white),
                      label: const Text('Acompanhar serviço', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                          final conv = await chat.openOrCreateConversation(
                            bookingId: ap.id,
                            clientId: auth.user?.id ?? ap.userId,
                            clientName: auth.user?.name ?? ap.userName,
                            establishmentId: ap.establishmentId,
                            establishmentName: ap.establishmentName,
                            token: auth.token!,
                          );
                          if (!context.mounted) return;
                          Navigator.pushNamed(context, '/chat', arguments: conv);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Não foi possível abrir o chat'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline,
                          size: 16, color: AppColors.primary),
                      label: const Text('Mensagem',
                          style: TextStyle(color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],

                if (isConcluido) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.isReviewed ? null : () => _showAvaliarDialog(context),
                      icon: Icon(
                        widget.isReviewed ? Icons.star : Icons.star_outline,
                        size: 16,
                        color: widget.isReviewed ? AppColors.greyLight : AppColors.warning,
                      ),
                      label: Text(
                        widget.isReviewed ? 'Avaliado' : 'Avaliar estabelecimento',
                        style: TextStyle(
                            color: widget.isReviewed ? AppColors.greyLight : AppColors.warning),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: widget.isReviewed ? AppColors.greyLight : AppColors.warning),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],

                if (ap.canCancel) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => widget.onCancel(ap),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Cancelar agendamento',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.grey))),
        ],
      );
}

class _PagamentoChip extends StatelessWidget {
  final String label;
  final bool estornado;
  final bool capturado;
  const _PagamentoChip({required this.label, required this.estornado, required this.capturado});

  @override
  Widget build(BuildContext context) {
    final color = estornado
        ? AppColors.danger
        : capturado
            ? AppColors.success
            : AppColors.primary;
    final icon = estornado
        ? Icons.replay
        : capturado
            ? Icons.check_circle
            : Icons.lock_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
