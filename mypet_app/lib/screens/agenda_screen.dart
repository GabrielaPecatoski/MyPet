import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/pagamento_provider.dart';
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

  Future<void> _pay(AppointmentModel booking) async {
    final auth = context.read<AuthProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayBookingSheet(booking: booking, token: auth.token!),
    );
    if (!mounted) return;
    context.read<BookingProvider>().loadUserBookings(
          token: auth.token!,
          userId: auth.user!.id,
        );
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
                        appointments: proximos, onCancel: _cancel, onPay: _pay),
                    _BookingList(
                        appointments: pendentes, onCancel: _cancel, onPay: _pay),
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
  final Future<void> Function(AppointmentModel) onPay;

  const _BookingList({
    required this.appointments,
    required this.onCancel,
    required this.onPay,
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
      itemBuilder: (_, i) => _BookingCard(
        appointment: appointments[i],
        onCancel: onCancel,
        onPay: onPay,
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Future<void> Function(AppointmentModel) onCancel;
  final Future<void> Function(AppointmentModel) onPay;

  const _BookingCard({
    required this.appointment,
    required this.onCancel,
    required this.onPay,
  });

  Color get _statusColor {
    switch (appointment.effectiveStatus) {
      case 'CONFIRMADO': return AppColors.success;
      case 'A_CAMINHO':  return AppColors.primary;
      case 'PENDENTE':   return AppColors.warning;
      case 'CANCELADO':
      case 'RECUSADO':   return AppColors.danger;
      default:           return AppColors.grey;
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

            if (ap.isActive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ap.pago
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ap.pago ? Icons.check_circle_outline : Icons.payment_outlined,
                          size: 13,
                          color: ap.pago ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ap.pago ? 'Pagamento realizado' : 'Aguardando pagamento',
                          style: TextStyle(
                            fontSize: 11,
                            color: ap.pago ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!ap.pago)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'O valor só é creditado ao estabelecimento após o serviço concluído.',
                    style: const TextStyle(fontSize: 10, color: AppColors.grey),
                  ),
                ),
            ],

            if (ap.canPay) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onPay(ap),
                  icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                  label: const Text('Realizar pagamento',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],

            if (ap.isConfirmado || ap.isACaminho) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/tracking', arguments: ap),
                  icon: Icon(
                    ap.isACaminho ? Icons.directions_car : Icons.location_on_outlined,
                    size: 16, color: Colors.white,
                  ),
                  label: Text(
                    ap.isACaminho ? 'Estabelecimento a caminho!' : 'Acompanhar serviço',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ap.isACaminho ? AppColors.primary : AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

class _PayBookingSheet extends StatefulWidget {
  final AppointmentModel booking;
  final String token;

  const _PayBookingSheet({required this.booking, required this.token});

  @override
  State<_PayBookingSheet> createState() => _PayBookingSheetState();
}

class _PayBookingSheetState extends State<_PayBookingSheet> {
  int _metodoIdx = 0;
  final _cardNumCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardExpCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();

  static const _metodos = [
    ('PIX',         Icons.qr_code_2,           'Pix'),
    ('CREDIT_CARD', Icons.credit_card,          'Crédito'),
    ('DEBIT_CARD',  Icons.credit_card_outlined, 'Débito'),
    ('CASH',        Icons.money,                'Dinheiro'),
    ('BOLETO',      Icons.receipt_long,         'Boleto'),
  ];

  @override
  void dispose() {
    _cardNumCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardExpCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  String get _selectedMethod => _metodos[_metodoIdx].$1;
  bool get _isCard =>
      _selectedMethod == 'CREDIT_CARD' || _selectedMethod == 'DEBIT_CARD';

  Future<void> _confirmar() async {
    if (_isCard && _cardNumCtrl.text.replaceAll(' ', '').length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o número do cartão completo'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final pagamento = context.read<PagamentoProvider>();

    await pagamento.confirmar(
      userId: auth.user?.id ?? 'guest',
      amount: widget.booking.price,
      method: _selectedMethod,
      deliveryMethod: 'PICKUP',
      cardNumber: _isCard ? _cardNumCtrl.text.replaceAll(' ', '') : null,
    );

    if (!mounted) return;

    if (pagamento.status == PagamentoStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pagamento.errorMessage ?? 'Erro ao processar pagamento'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final payment = pagamento.paymentResult!;
    final payStatus = payment['status'] as String? ?? '';

    if (payStatus == 'REJECTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payment['rejectionReason'] ?? 'Pagamento recusado'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final ok = await context.read<BookingProvider>().markAsPaid(
          token: widget.token,
          bookingId: widget.booking.id,
        );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<BookingProvider>().error ?? 'Erro'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pagamento realizado com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PagamentoProvider>().isLoading ||
        context.watch<BookingProvider>().isLoading;
    final ap = widget.booking;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Realizar Pagamento',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          _sumRow('Serviço:', ap.serviceName),
                          _sumRow('Pet:', ap.petName),
                          _sumRow('Local:', ap.establishmentName),
                          _sumRow('Horário:', ap.time),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.dark)),
                              Text(
                                'R\$ ${ap.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'O valor será creditado ao estabelecimento após o serviço ser concluído.',
                            style: TextStyle(fontSize: 11, color: AppColors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Forma de pagamento',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark)),
                    const SizedBox(height: 12),
                    ...List.generate(
                      _metodos.length,
                      (i) => _PayTile(
                        icon: _metodos[i].$2,
                        label: _metodos[i].$3,
                        selected: _metodoIdx == i,
                        onTap: () => setState(() => _metodoIdx = i),
                      ),
                    ),

                    if (_isCard) ...[
                      const SizedBox(height: 16),
                      const Text('Dados do cartão',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark)),
                      const SizedBox(height: 12),
                      _field(_cardNumCtrl, 'Número do cartão',
                          maxLen: 19, fmt: [_AgendaCardNumFmt()]),
                      const SizedBox(height: 10),
                      _field(_cardNameCtrl, 'Nome no cartão',
                          type: TextInputType.text,
                          caps: TextCapitalization.characters),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _field(_cardExpCtrl, 'MM/AA',
                                maxLen: 5, fmt: [_AgendaExpiryFmt()])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _field(_cardCvvCtrl, 'CVV',
                                maxLen: 3, obscure: true)),
                      ]),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Confirmar Pagamento',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sumRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                    fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _field(TextEditingController ctrl, String hint,
      {int? maxLen,
      List<TextInputFormatter>? fmt,
      TextInputType type = TextInputType.number,
      TextCapitalization caps = TextCapitalization.none,
      bool obscure = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: caps,
      obscureText: obscure,
      maxLength: maxLen,
      inputFormatters: fmt,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PayTile(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.greyLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(children: [
            Icon(icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.grey),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? AppColors.primary : AppColors.dark)),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
          ]),
        ),
      );
}

class _AgendaCardNumFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
        text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

class _AgendaExpiryFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    String str = digits;
    if (digits.length >= 3) str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    if (str.length > 5) str = str.substring(0, 5);
    return TextEditingValue(
        text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}
