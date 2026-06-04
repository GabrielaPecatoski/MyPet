import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/mypet_app_bar.dart';

class PagamentoScreen extends StatefulWidget {
  const PagamentoScreen({super.key});
  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  int _entregaIdx = 0;
  int _metodoIdx = 0;
  final _enderecoCtrl = TextEditingController();
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
    for (final c in [_enderecoCtrl, _cardNumCtrl, _cardNameCtrl, _cardExpCtrl, _cardCvvCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _selectedMethod => _metodos[_metodoIdx].$1;
  bool get _isCard => _selectedMethod == 'CREDIT_CARD' || _selectedMethod == 'DEBIT_CARD';

  Future<void> _confirmar() async {
    if (_isCard && _cardNumCtrl.text.replaceAll(' ', '').length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o número do cartão completo'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_entregaIdx == 1 && _enderecoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o endereço de entrega'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final pagamento = context.read<PagamentoProvider>();

    await pagamento.confirmar(
      userId: auth.user?.id ?? 'guest',
      amount: cart.total,
      method: _selectedMethod,
      deliveryMethod: _entregaIdx == 0 ? 'PICKUP' : 'DELIVERY',
      deliveryAddress: _entregaIdx == 1 ? _enderecoCtrl.text.trim() : null,
      cardNumber: _isCard ? _cardNumCtrl.text.replaceAll(' ', '') : null,
      installments: _selectedMethod == 'CREDIT_CARD' ? _parcelas : null,
      token: auth.token,
    );

    if (!mounted) return;

    if (pagamento.status == PagamentoStatus.success) {
      cart.clear();
      _showResult(pagamento.paymentResult!);
    } else if (pagamento.status == PagamentoStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pagamento.errorMessage ?? 'Erro'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showResult(Map<String, dynamic> payment) {
    final status = payment['status'] as String;
    final method = payment['method'] as String;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ResultSheet(
        status: status,
        method: method,
        pixKey: payment['pixKey'] as String?,
        boletoCode: payment['boletoCode'] as String?,
        cardLastFour: payment['cardLastFour'] as String?,
        installments: payment['installments'] as int?,
        rejectionReason: payment['rejectionReason'] as String?,
        onDone: () {
          Navigator.of(context)
            ..pop() // bottom sheet
            ..pop() // pagamento
            ..pop(); // carrinho
        },
        onRetry: status == 'REJECTED' ? () {
          Navigator.of(context).pop();
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final loading = context.watch<PagamentoProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pagamento',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 20),

            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumo do pedido',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                const SizedBox(height: 12),
                ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.quantity}x ${item.name}',
                          style: const TextStyle(fontSize: 13, color: AppColors.dark),
                          overflow: TextOverflow.ellipsis)),
                      Text('R\$ ${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('R\$ ${cart.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 16),

            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Forma de entrega',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _EntregaChip(
                    label: 'Retirar no local', icon: Icons.store_outlined,
                    selected: _entregaIdx == 0, onTap: () => setState(() => _entregaIdx = 0),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _EntregaChip(
                    label: 'Entrega', icon: Icons.delivery_dining,
                    selected: _entregaIdx == 1, onTap: () => setState(() => _entregaIdx = 1),
                  )),
                ]),
                if (_entregaIdx == 1) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _enderecoCtrl,
                    decoration: InputDecoration(
                      hintText: 'Endereço de entrega',
                      hintStyle: const TextStyle(color: AppColors.grey),
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
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
                  _field(_cardNumCtrl, 'Número do cartão', maxLen: 19,
                      fmt: [_CardNumberFormatter()]),
                  const SizedBox(height: 10),
                  _field(_cardNameCtrl, 'Nome no cartão', caps: TextCapitalization.characters),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _field(_cardExpCtrl, 'MM/AA', maxLen: 5,
                        fmt: [_ExpiryFormatter()])),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_cardCvvCtrl, 'CVV', maxLen: 3,
                        type: TextInputType.number, obscure: true)),
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
                        final val = (cart.total / n).toStringAsFixed(2);
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
                onPressed: loading ? null : _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: loading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmar Pedido',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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

class _ResultSheet extends StatelessWidget {
  final String status;
  final String method;
  final String? pixKey;
  final String? boletoCode;
  final String? cardLastFour;
  final int? installments;
  final String? rejectionReason;
  final VoidCallback onDone;
  final VoidCallback? onRetry;

  const _ResultSheet({
    required this.status, required this.method,
    this.pixKey, this.boletoCode, this.cardLastFour,
    this.installments, this.rejectionReason,
    required this.onDone, this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final approved = status == 'APPROVED';
    final rejected = status == 'REJECTED';
    final pending = status == 'PENDING';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: approved ? AppColors.success : rejected ? AppColors.danger : AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: Icon(
              approved ? Icons.check : rejected ? Icons.close : Icons.schedule,
              color: Colors.white, size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            approved ? 'Pagamento Aprovado!'
              : rejected ? 'Pagamento Recusado'
              : 'Aguardando Pagamento',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
          ),
          const SizedBox(height: 8),
          Text(
            approved ? 'Seu pedido foi confirmado com sucesso.'
              : rejected ? rejectionReason ?? 'Não foi possível processar o pagamento.'
              : _pendingMessage(method),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey, fontSize: 13),
          ),

          if (pixKey != null) ...[
            const SizedBox(height: 20),
            _InfoBox(
              title: 'Chave Pix',
              value: pixKey!,
              copyable: true,
            ),
          ],

          if (boletoCode != null) ...[
            const SizedBox(height: 20),
            _InfoBox(
              title: 'Código do Boleto',
              value: boletoCode!,
              copyable: true,
            ),
            const SizedBox(height: 6),
            const Text('Vence em 3 dias úteis',
                style: TextStyle(fontSize: 11, color: AppColors.grey)),
          ],

          if (cardLastFour != null && approved) ...[
            const SizedBox(height: 12),
            Text(
              'Cartão final $cardLastFour'
              '${installments != null && installments! > 1 ? ' · ${installments}x' : ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
          ],

          const SizedBox(height: 28),

          if (onRetry != null)
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tentar outro método',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ),

          if (onRetry != null) const SizedBox(height: 10),

          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: approved ? AppColors.primary : AppColors.dark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                approved ? 'Continuar' : pending ? 'Ok, entendi' : 'Voltar à loja',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pendingMessage(String method) {
    if (method == 'BOLETO') return 'Pague o boleto para confirmar seu pedido.';
    if (method == 'CASH') return 'Pague no momento da retirada ou entrega.';
    return 'Seu pagamento está sendo processado.';
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

class _EntregaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _EntregaChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.primary : AppColors.greyLight, width: selected ? 2 : 1),
      ),
      child: Column(children: [
        Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.grey),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.primary : AppColors.grey)),
      ]),
    ),
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
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    String str = digits;
    if (digits.length >= 3) str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    if (str.length > 5) str = str.substring(0, 5);
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
