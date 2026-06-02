import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
<<<<<<< HEAD
=======
import '../services/review_service.dart';
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
import '../widgets/mypet_app_bar.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
<<<<<<< HEAD
=======
  final Set<String> _reviewedBookingIds = {};
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

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
<<<<<<< HEAD
=======
    _loadReviewed(auth.token!);
  }

  Future<void> _loadReviewed(String token) async {
    try {
      final reviews = await ReviewService.getMyReviews(token: token);
      if (mounted) {
        setState(() {
          _reviewedBookingIds.addAll(
            reviews.where((r) => r.bookingId.isNotEmpty).map((r) => r.bookingId),
          );
        });
      }
    } catch (_) {}
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
    final proximos = booking.confirmados;
    final pendentes = booking.pendentes;
=======
    final proximos = booking.ativos;
    final historico = booking.historico;
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

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
<<<<<<< HEAD
                      const Text('Pendentes'),
                      if (pendentes.isNotEmpty) ...[
=======
                      const Text('Próximos'),
                      if (booking.pendentes.isNotEmpty) ...[
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
<<<<<<< HEAD
                          child: Text('${pendentes.length}',
=======
                          child: Text('${booking.pendentes.length}',
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
=======
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
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _load(),
                color: AppColors.primary,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BookingList(
<<<<<<< HEAD
                        appointments: proximos, onCancel: _cancel),
                    _BookingList(
                        appointments: pendentes, onCancel: _cancel),
=======
                        appointments: proximos,
                        onCancel: _cancel,
                        reviewedBookingIds: _reviewedBookingIds,
                        onReviewed: (bookingId) => setState(() => _reviewedBookingIds.add(bookingId))),
                    _BookingList(
                        appointments: historico,
                        onCancel: _cancel,
                        isHistory: true,
                        reviewedBookingIds: _reviewedBookingIds,
                        onReviewed: (bookingId) => setState(() => _reviewedBookingIds.add(bookingId))),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD

  const _BookingList(
      {required this.appointments, required this.onCancel});
=======
  final bool isHistory;
  final Set<String> reviewedBookingIds;
  final void Function(String bookingId) onReviewed;

  const _BookingList({
    required this.appointments,
    required this.onCancel,
    required this.reviewedBookingIds,
    required this.onReviewed,
    this.isHistory = false,
  });
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

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
<<<<<<< HEAD
            const Text('Nenhum agendamento',
                style: TextStyle(
=======
            Text(
                isHistory ? 'Nenhum histórico' : 'Nenhum agendamento',
                style: const TextStyle(
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                    color: AppColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
<<<<<<< HEAD
            const Text('Seus agendamentos aparecerão aqui',
                style: TextStyle(color: AppColors.grey, fontSize: 13)),
=======
            Text(
                isHistory
                    ? 'Agendamentos concluídos ou cancelados aparecerão aqui'
                    : 'Agende um serviço e ele aparecerá aqui',
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
                textAlign: TextAlign.center),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: appointments.length,
<<<<<<< HEAD
      itemBuilder: (_, i) =>
          _BookingCard(appointment: appointments[i], onCancel: onCancel),
=======
      itemBuilder: (_, i) => _BookingCard(
        appointment: appointments[i],
        onCancel: onCancel,
        isReviewed: reviewedBookingIds.contains(appointments[i].id),
        onReviewed: () => onReviewed(appointments[i].id),
      ),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    );
  }
}

class _BookingCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Future<void> Function(AppointmentModel) onCancel;
<<<<<<< HEAD

  const _BookingCard(
      {required this.appointment, required this.onCancel});
=======
  final bool isReviewed;
  final VoidCallback onReviewed;

  const _BookingCard({
    required this.appointment,
    required this.onCancel,
    required this.isReviewed,
    required this.onReviewed,
  });
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

  Color get _statusColor {
    switch (appointment.status) {
      case 'CONFIRMADO':
        return AppColors.success;
      case 'PENDENTE':
        return AppColors.warning;
      case 'CANCELADO':
      case 'RECUSADO':
        return AppColors.danger;
<<<<<<< HEAD
=======
      case 'CONCLUIDO':
        return AppColors.grey;
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
      default:
        return AppColors.grey;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return '${d.day} de ${months[d.month - 1]} de ${d.year}';
  }

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    final ap = appointment;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
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
                  child: const Icon(Icons.pets,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ap.petName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
=======
  void _showAvaliarDialog(BuildContext context) {
    int selectedRating = 0;
    final commentCtrl = TextEditingController();

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
              Text(
                appointment.establishmentName,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Como foi sua experiência?',
                style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
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
                      size: 34,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
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
                        try {
                          await ReviewService.submitReview(
                            establishmentId: appointment.establishmentId,
                            bookingId: appointment.id,
                            rating: selectedRating,
                            comment: commentCtrl.text.trim().isEmpty
                                ? null
                                : commentCtrl.text.trim(),
                            token: auth.token,
                          );
                        } catch (_) {}
                        onReviewed();
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Enviar Avaliação',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.greyLight),
            const SizedBox(height: 12),

            _row(Icons.location_on_outlined, ap.establishmentName),
            const SizedBox(height: 6),
            _row(Icons.calendar_today_outlined, _formatDate(ap.date)),
            const SizedBox(height: 6),
            _row(Icons.access_time_outlined, ap.time),

            if (ap.price > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Valor: R\$ ${ap.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary),
              ),
            ],

            if (ap.isConfirmado) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/tracking', arguments: ap),
                  icon: const Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.white),
                  label: const Text('Acompanhar serviço',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            if (ap.canCancel) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onCancel(ap),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
    );
  }

<<<<<<< HEAD
=======
  @override
  Widget build(BuildContext context) {
    final ap = appointment;
    final isConcluido = ap.status == 'CONCLUIDO';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
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
                  child: const Icon(Icons.pets,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ap.petName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
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

            if (ap.price > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Valor: R\$ ${ap.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary),
              ),
            ],

            if (ap.isConfirmado) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/tracking', arguments: ap),
                  icon: const Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.white),
                  label: const Text('Acompanhar serviço',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            if (isConcluido) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isReviewed ? null : () => _showAvaliarDialog(context),
                  icon: Icon(
                    isReviewed ? Icons.star : Icons.star_outline,
                    size: 16,
                    color: isReviewed ? AppColors.greyLight : AppColors.warning,
                  ),
                  label: Text(
                    isReviewed ? 'Avaliado' : 'Avaliar estabelecimento',
                    style: TextStyle(
                        color: isReviewed ? AppColors.greyLight : AppColors.warning),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: isReviewed ? AppColors.greyLight : AppColors.warning),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                  onPressed: () => onCancel(ap),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
    );
  }

>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.grey),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.grey))),
        ],
      );
}
