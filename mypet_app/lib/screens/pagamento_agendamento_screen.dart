import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/pagamento_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/mypet_app_bar.dart';

class PagamentoAgendamentoScreen extends StatefulWidget {
  const PagamentoAgendamentoScreen({super.key});

  @override
  State<PagamentoAgendamentoScreen> createState() => _PagamentoAgendamentoScreenState();
}

class _PagamentoAgendamentoScreenState extends State<PagamentoAgendamentoScreen> {
  int _metodoIdx = 0;
  final _cardNumCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardExpCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();
  int _parcelas = 1;

  static const _metodos = [
    ('PIX',         Icons.qr_code_2,           'Pix'),
    ('CREDIT_CARD', Icons.credit_card,          'Crédito'),
    ('DEBIT_CARD',  Icons.credit_card_outlined, 'Débito'),
    ('CASH',        Icons.money,                'Dinheiro'),
    ('BOLETO',      Icons.barcode_reader,       'Boleto'),
  ];

  @override
  void dispose() {
    for (final c in [_cardNumCtrl, _cardNameCtrl, _cardExpCtrl, _cardCvvCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _selectedMethod => _metodos[_metodoIdx].$1;
  bool get _isCard => _selectedMethod == 'CREDIT_CARD' || _selectedMethod == 'DEBIT_CARD';

  Future<void> _confirmar(AppointmentModel booking) async {
    if (_isCard && _cardNumCtrl.text.replaceAll(' ', '').length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o número do cartão completo'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (_selectedMethod == 'PIX' || _selectedMethod == 'BOLETO') {
      _showPendingSheet(booking);
      return;
    }

    await _processar(booking);
  }

  void _showPendingSheet(AppointmentModel booking) {
    final isPix = _selectedMethod == 'PIX';
    final pixKey = isPix ? 'mypet@pagamentos.com' : null;
    final boletoCode = !isPix
        ? '34191.75501 34191.75501 34191.75501 1 ${booking.price.toStringAsFixed(2).replaceAll('.', '').padLeft(14, '0')}'
        : null;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PendingSheet(
        isPix: isPix,
        pixKey: pixKey,
        boletoCode: boletoCode,
        amount: booking.price,
        onJaPaguei: () async {
          Navigator.pop(ctx);
          await _processar(booking);
        },
        onCancelar: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _processar(AppointmentModel booking) async {
    final auth = context.read<AuthProvider>();
    final pagamento = context.read<PagamentoProvider>();

    await pagamento.confirmarAgendamento(
      bookingId: booking.id,
      amount: booking.price,
      method: _selectedMethod,
      token: auth.token ?? '',
      cardNumber: _isCard ? _cardNumCtrl.text.replaceAll(' ', '') : null,
      installments: _selectedMethod == 'CREDIT_CARD' ? _parcelas : null,
    );

    if (!mounted) return;

    if (pagamento.status == PagamentoStatus.success) {
      final bookingProv = context.read<BookingProvider>();
      await bookingProv.loadUserBookings(token: auth.token!, userId: auth.user!.id);
      if (!mounted) return;
      _showResult(pagamento.paymentResult!);
    } else if (pagamento.status == PagamentoStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pagamento.errorMessage ?? 'Erro'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showResult(Map<String, dynamic> payment) {
    final status = payment['status'] as String? ?? 'APPROVED';
    final method = payment['method'] as String? ?? _selectedMethod;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ResultSheet(
        status: status,
        method: method,
        cardLastFour: payment['cardLastFour'] as String?,
        installments: payment['installments'] as int?,
        rejectionReason: payment['rejectionReason'] as String?,
        onDone: () {
          Navigator.of(context)
            ..pop()
            ..pop();
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false, arguments: 1);
        },
        onRetry: status == 'REJECTED' ? () => Navigator.of(context).pop() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)?.settings.arguments as AppointmentModel?;
    if (booking == null) {
      return const Scaffold(body: Center(child: Text('Agendamento não encontrado')));
    }

    final loading = context.watch<PagamentoProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pagamento do Agendamento',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 20),

            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                const SizedBox(height: 12),
                _infoRow(Icons.pets, booking.petName),
                const SizedBox(height: 6),
                _infoRow(Icons.build_outlined, booking.serviceName),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined, booking.establishmentName),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('R\$ ${booking.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 16),

            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Forma de pagamento',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                const SizedBox(height: 12),
                ...List.generate(_metodos.length, (i) => _PagTile(
                  icon: _metodos[i].$2, label: _metodos[i].$3,
                  selected: _metodoIdx == i,
                  onTap: () => setState(() => _metodoIdx = i),
                )),
              ],
            )),
            const SizedBox(height: 16),

            if (_isCard)
              _Card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dados do cartão de ${_selectedMethod == 'CREDIT_CARD' ? 'crédito' : 'débito'}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 12),
                  _field(_cardNumCtrl, 'Número do cartão', maxLen: 19, fmt: [_CardNumberFormatter()]),
                  const SizedBox(height: 10),
                  _field(_cardNameCtrl, 'Nome no cartão', caps: TextCapitalization.characters),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _field(_cardExpCtrl, 'MM/AA', maxLen: 5, fmt: [_ExpiryFormatter()])),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_cardCvvCtrl, 'CVV', maxLen: 3, obscure: true)),
                  ]),
                  if (_selectedMethod == 'CREDIT_CARD') ...[
                    const SizedBox(height: 12),
                    const Text('Parcelas', style: TextStyle(fontSize: 13, color: AppColors.grey)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _parcelas,
                      decoration: InputDecoration(
                        filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: List.generate(12, (i) => i + 1).map((n) {
                        final val = (booking.price / n).toStringAsFixed(2);
                        return DropdownMenuItem(value: n, child: Text('${n}x de R\$ $val'));
                      }).toList(),
                      onChanged: (v) => setState(() => _parcelas = v ?? 1),
                    ),
                  ],
                ],
              )),

            if (_isCard) const SizedBox(height: 16),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : () => _confirmar(booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: loading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmar Pagamento',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 15, color: AppColors.grey),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.dark))),
    ],
  );

  Widget _field(TextEditingController ctrl, String hint, {
    int? maxLen, List<TextInputFormatter>? fmt,
    TextInputType type = TextInputType.number,
    TextCapitalization caps = TextCapitalization.none,
    bool obscure = false,
  }) {
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
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _PendingSheet extends StatelessWidget {
  final bool isPix;
  final String? pixKey;
  final String? boletoCode;
  final double amount;
  final VoidCallback onJaPaguei;
  final VoidCallback onCancelar;

  const _PendingSheet({
    required this.isPix,
    this.pixKey,
    this.boletoCode,
    required this.amount,
    required this.onJaPaguei,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(isPix ? Icons.qr_code_2 : Icons.barcode_reader,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            isPix ? 'Pague via Pix' : 'Pague o Boleto',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
          ),
          const SizedBox(height: 6),
          Text(
            isPix
                ? 'Copie a chave Pix abaixo, pague no seu banco e volte para confirmar.'
                : 'Copie o código do boleto, pague e volte para confirmar.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 20),

          if (pixKey != null) _InfoBox(title: 'Chave Pix', value: pixKey!, copyable: true),
          if (boletoCode != null) ...[
            _InfoBox(title: 'Código do Boleto', value: boletoCode!, copyable: true),
            const SizedBox(height: 6),
            const Text('Vence em 3 dias úteis',
                style: TextStyle(fontSize: 11, color: AppColors.grey)),
          ],

          const SizedBox(height: 8),
          Text('Valor: R\$ ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: onJaPaguei,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Já Paguei', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 44,
            child: TextButton(
              onPressed: onCancelar,
              child: const Text('Cancelar', style: TextStyle(color: AppColors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  final String status;
  final String method;
  final String? cardLastFour;
  final int? installments;
  final String? rejectionReason;
  final VoidCallback onDone;
  final VoidCallback? onRetry;

  const _ResultSheet({
    required this.status, required this.method,
    this.cardLastFour, this.installments, this.rejectionReason,
    required this.onDone, this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final approved = status == 'APPROVED';
    final rejected = status == 'REJECTED';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: approved ? AppColors.success : AppColors.danger,
              shape: BoxShape.circle,
            ),
            child: Icon(approved ? Icons.check : Icons.close, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            approved ? 'Pagamento Confirmado!' : 'Pagamento Recusado',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
          ),
          const SizedBox(height: 8),
          Text(
            approved
                ? 'Seu agendamento foi enviado ao estabelecimento. O valor ficará retido e só será repassado após a conclusão do serviço. Se for recusado, você recebe o estorno.'
                : rejectionReason ?? 'Não foi possível processar o pagamento.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey, fontSize: 13),
          ),

          if (cardLastFour != null && approved) ...[
            const SizedBox(height: 12),
            Text(
              'Cartão final $cardLastFour'
              '${installments != null && installments! > 1 ? ' · ${installments}x' : ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],

          const SizedBox(height: 28),

          if (rejected && onRetry != null) ...[
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tentar outro método', style: TextStyle(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: approved ? AppColors.primary : AppColors.dark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                approved ? 'Ver Minha Agenda' : 'Voltar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;
  final bool copyable;
  const _InfoBox({required this.title, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark),
                  overflow: TextOverflow.ellipsis)),
              if (copyable)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copiado!'), duration: Duration(milliseconds: 800)),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.copy, size: 16, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
    ),
    child: child,
  );
}

class _PagTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PagTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.primary : AppColors.greyLight, width: selected ? 2 : 1),
      ),
      child: Row(children: [
        Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.grey),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? AppColors.primary : AppColors.dark)),
        const Spacer(),
        if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
      ]),
    ),
  );
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    String str = digits;
    if (digits.length >= 3) str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    if (str.length > 5) str = str.substring(0, 5);
    return TextEditingValue(text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}
