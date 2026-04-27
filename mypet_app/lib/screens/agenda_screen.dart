import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/mypet_app_bar.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen>
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
    final proximos = booking.confirmados;
    final pendentes = booking.pendentes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: Column(
        children: [
          // ── Tabs ──────────────────────────────────────────────
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
                const Tab(text: 'Próximos'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pendentes'),
                      if (pendentes.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${pendentes.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Conteúdo das abas ──────────────────────────────────
          if (booking.isLoading)
            const Expanded(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _load(),
                color: AppColors.primary,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BookingList(
                        appointments: proximos, onCancel: _cancel),
                    _BookingList(
                        appointments: pendentes, onCancel: _cancel),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Lista de cards ──────────────────────────────────────────────────
class _BookingList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final Future<void> Function(AppointmentModel) onCancel;

  const _BookingList(
      {required this.appointments, required this.onCancel});

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
            const Text('Nenhum agendamento',
                style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Seus agendamentos aparecerão aqui',
                style: TextStyle(color: AppColors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: appointments.length,
      itemBuilder: (_, i) =>
          _BookingCard(appointment: appointments[i], onCancel: onCancel),
    );
  }
}

// ── Card individual ─────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Future<void> Function(AppointmentModel) onCancel;

  const _BookingCard(
      {required this.appointment, required this.onCancel});

  Color get _statusColor {
    switch (appointment.status) {
      case 'CONFIRMADO':
        return AppColors.success;
      case 'PENDENTE':
        return AppColors.warning;
      case 'CANCELADO':
      case 'RECUSADO':
        return AppColors.danger;
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
            // ── Cabeçalho: avatar + nome + badge ──
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

            // ── Detalhes ──
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

            // ── Botão cancelar ──
            if (ap.canCancel) ...[
              const SizedBox(height: 12),
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
