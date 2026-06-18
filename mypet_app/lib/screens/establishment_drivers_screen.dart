import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../providers/establishment_staff_provider.dart';
import '../widgets/mypet_app_bar.dart';

class EstabMotoristasScreen extends StatefulWidget {
  const EstabMotoristasScreen({super.key});

  @override
  State<EstabMotoristasScreen> createState() => _EstabMotoristasScreenState();
}

class _EstabMotoristasScreenState extends State<EstabMotoristasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final estabProvider = context.read<EstablishmentProvider>();
    if (auth.token == null) return;

    if (estabProvider.establishmentId == null) {
      await estabProvider.loadByOwner(
        token: auth.token!,
        ownerId: auth.user!.id,
        ownerName: auth.user!.name,
        ownerPhone: auth.user!.phone,
      );
    }
    final estabId = estabProvider.establishmentId;
    if (estabId == null) return;
    final staff = context.read<EstablishmentStaffProvider>();
    staff.init(establishmentId: estabId, token: auth.token!);
    await staff.loadDrivers();
  }

  Future<void> _desassociar(DriverModel driver) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover motorista?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Deseja remover ${driver.name} deste estabelecimento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Remover',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await context
        .read<EstablishmentStaffProvider>()
        .dissociateDriver(driver.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Motorista removido do estabelecimento'
              : 'Erro ao remover motorista'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _abrirBuscarMotorista() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => EstabMotoristaBuscarSheet(onAssociado: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estab = context.watch<EstablishmentProvider>();
    final staff = context.watch<EstablishmentStaffProvider>();
    final motoristas = staff.drivers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            estab.establishmentId == null ? null : _abrirBuscarMotorista,
        backgroundColor: AppColors.estab,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Adicionar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: staff.loadingDrivers
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.estab))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.estab,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  const Text('Motoristas',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark)),
                  const SizedBox(height: 4),
                  const Text(
                    'Motoristas associados a este estabelecimento.',
                    style: TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                  const SizedBox(height: 20),
                  if (motoristas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 48, color: AppColors.greyLight),
                          SizedBox(height: 10),
                          Text('Nenhum motorista associado',
                              style: TextStyle(
                                  color: AppColors.dark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          SizedBox(height: 4),
                          Text(
                            'Toque em "Adicionar" para buscar ou cadastrar um motorista.',
                            style: TextStyle(
                                color: AppColors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...motoristas.map((d) => EstabMotoristaCard(
                          driver: d,
                          onRemover: () => _desassociar(d),
                        )),
                ],
              ),
            ),
    );
  }
}

class EstabMotoristaBuscarSheet extends StatefulWidget {
  final VoidCallback onAssociado;
  const EstabMotoristaBuscarSheet({
    super.key,
    required this.onAssociado,
  });

  @override
  State<EstabMotoristaBuscarSheet> createState() => EstabMotoristaBuscarSheetState();
}

class EstabMotoristaBuscarSheetState extends State<EstabMotoristaBuscarSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _cpfCtrl = TextEditingController();
  DriverModel? _encontrado;
  bool _buscando = false;
  bool _associando = false;
  String? _erroMsg;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarPorCpf() async {
    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) {
      setState(() => _erroMsg = 'CPF deve ter 11 dígitos');
      return;
    }
    setState(() {
      _buscando = true;
      _encontrado = null;
      _erroMsg = null;
    });
    try {
      final driver =
          await context.read<EstablishmentStaffProvider>().findDriverByCpf(cpf);
      setState(() {
        _encontrado = driver;
        _erroMsg = driver == null ? 'Motorista não encontrado' : null;
      });
    } catch (_) {
      setState(() => _erroMsg = 'Erro ao buscar motorista');
    } finally {
      setState(() => _buscando = false);
    }
  }

  Future<void> _associar(DriverModel driver) async {
    if (driver.isAssociado) {
      setState(() => _erroMsg = 'Motorista já está associado a outro estabelecimento');
      return;
    }
    setState(() => _associando = true);
    final ok = await context
        .read<EstablishmentStaffProvider>()
        .associateDriver(driver.id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      widget.onAssociado();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver.name} associado com sucesso!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _associando = false;
        _erroMsg = 'Erro ao associar motorista';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adicionar Motorista',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      indicator: BoxDecoration(
                        color: AppColors.estab,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.grey,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Buscar por CPF'),
                        Tab(text: 'Cadastrar novo'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _BuscarTab(
                    cpfCtrl: _cpfCtrl,
                    encontrado: _encontrado,
                    buscando: _buscando,
                    associando: _associando,
                    erroMsg: _erroMsg,
                    onBuscar: _buscarPorCpf,
                    onAssociar: _associar,
                  ),
                  _CadastrarTab(
                    onCadastrado: () {
                      Navigator.pop(context);
                      widget.onAssociado();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuscarTab extends StatelessWidget {
  final TextEditingController cpfCtrl;
  final DriverModel? encontrado;
  final bool buscando;
  final bool associando;
  final String? erroMsg;
  final VoidCallback onBuscar;
  final Future<void> Function(DriverModel) onAssociar;

  const _BuscarTab({
    required this.cpfCtrl,
    required this.encontrado,
    required this.buscando,
    required this.associando,
    required this.erroMsg,
    required this.onBuscar,
    required this.onAssociar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'O motorista deve estar cadastrado no sistema. Informe o CPF para localizá-lo.',
          style: TextStyle(fontSize: 13, color: AppColors.grey),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: cpfCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'CPF do motorista',
            prefixIcon:
                const Icon(Icons.badge, color: AppColors.estab, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.greyLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.greyLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.estab, width: 2),
            ),
          ),
          onFieldSubmitted: (_) => onBuscar(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: buscando ? null : onBuscar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.estab,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: buscando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Buscar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        if (erroMsg != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(erroMsg!,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
        ],
        if (encontrado != null) ...[
          const SizedBox(height: 16),
          EstabMotoristaCard(
            driver: encontrado!,
            onAssociar: encontrado!.isAssociado
                ? null
                : () => onAssociar(encontrado!),
            associando: associando,
          ),
        ],
      ],
    );
  }
}

class _CadastrarTab extends StatefulWidget {
  final VoidCallback onCadastrado;
  const _CadastrarTab({
    required this.onCadastrado,
  });

  @override
  State<_CadastrarTab> createState() => _CadastrarTabState();
}

class _CadastrarTabState extends State<_CadastrarTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _cnhCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  String _vehicleType = 'CARRO';
  bool _loading = false;
  bool _obscureSenha = true;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _cpfCtrl, _emailCtrl,
      _senhaCtrl, _cnhCtrl, _modelCtrl, _plateCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final driver =
          await context.read<EstablishmentStaffProvider>().registerDriver(
                name: _nameCtrl.text.trim(),
                email: _emailCtrl.text.trim(),
                password: _senhaCtrl.text,
                phone: _phoneCtrl.text.trim(),
                cpf: _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
                cnh: _cnhCtrl.text.trim(),
                vehicleType: _vehicleType,
                vehicleModel: _modelCtrl.text.trim(),
                vehiclePlate: _plateCtrl.text.trim().toUpperCase(),
              );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${driver.name} cadastrado e associado!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onCadastrado();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _field(_nameCtrl, 'Nome completo', Icons.person, required: true),
          const SizedBox(height: 10),
          _field(_phoneCtrl, 'Telefone', Icons.phone,
              required: true, keyboard: TextInputType.phone),
          const SizedBox(height: 10),
          _field(_cpfCtrl, 'CPF', Icons.badge,
              required: true,
              keyboard: TextInputType.number,
              validator: (v) {
                if ((v?.replaceAll(RegExp(r'\D'), '') ?? '').length != 11) {
                  return 'CPF deve ter 11 dígitos';
                }
                return null;
              }),
          const SizedBox(height: 10),
          _field(_emailCtrl, 'E-mail', Icons.email_outlined,
              required: true,
              keyboard: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'E-mail inválido' : null),
          const SizedBox(height: 10),
          TextFormField(
            controller: _senhaCtrl,
            obscureText: _obscureSenha,
            decoration: InputDecoration(
              labelText: 'Senha (mín. 6 caracteres)',
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.estab, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.grey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureSenha = !_obscureSenha),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.greyLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.greyLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.estab, width: 2),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 10),
          _field(_cnhCtrl, 'CNH', Icons.credit_card, required: true),
          const SizedBox(height: 14),
          const Text('Veículo',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (val, label, icon) in [
                ('CARRO', 'Carro', Icons.directions_car),
                ('MOTO', 'Moto', Icons.two_wheeler),
                ('VAN', 'Van', Icons.airport_shuttle),
              ])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _vehicleType = val),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _vehicleType == val
                            ? AppColors.estab
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _vehicleType == val
                              ? AppColors.estab
                              : AppColors.greyLight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(icon,
                              size: 20,
                              color: _vehicleType == val
                                  ? Colors.white
                                  : AppColors.grey),
                          const SizedBox(height: 3),
                          Text(label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _vehicleType == val
                                      ? Colors.white
                                      : AppColors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _field(_modelCtrl, 'Modelo (ex: Fiat Uno)', Icons.directions_car,
              required: true),
          const SizedBox(height: 10),
          _field(_plateCtrl, 'Placa (ex: ABC1D23)',
              Icons.confirmation_number,
              required: true,
              caps: TextCapitalization.characters,
              validator: (v) =>
                  (v?.trim().length ?? 0) < 7 ? 'Placa inválida' : null),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.estab,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Cadastrar e Associar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.words,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        textCapitalization: caps,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.estab, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.greyLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.greyLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.estab, width: 2),
          ),
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obrigatório'
                    : null
                : null),
      );
}

class EstabMotoristaCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback? onRemover;
  final VoidCallback? onAssociar;
  final bool associando;

  const EstabMotoristaCard({
    required this.driver,
    this.onRemover,
    this.onAssociar,
    this.associando = false,
  });

  IconData get _vehicleIcon {
    switch (driver.vehicleType) {
      case 'MOTO': return Icons.two_wheeler;
      case 'VAN':  return Icons.airport_shuttle;
      default:     return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: driver.isAtivo
                            ? AppColors.primaryLight
                            : AppColors.greyLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_vehicleIcon,
                          color: driver.isAtivo
                              ? AppColors.estab
                              : AppColors.grey,
                          size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.dark)),
                          Text(
                            '${driver.vehicleTypeLabel} • ${driver.vehicleModel}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (driver.isAssociado)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Associado',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.greyLight),
                const SizedBox(height: 10),
                _row(Icons.confirmation_number_outlined,
                    'Placa: ${driver.vehiclePlate}'),
                const SizedBox(height: 3),
                _row(Icons.credit_card_outlined, 'CNH: ${driver.cnh}'),
                const SizedBox(height: 3),
                _row(Icons.phone_outlined, driver.phone),
              ],
            ),
          ),
          if (onRemover != null || onAssociar != null) ...[
            const Divider(height: 1, color: AppColors.greyLight),
            if (onAssociar != null)
              InkWell(
                onTap: associando ? null : onAssociar,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Center(
                    child: associando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: AppColors.estab, strokeWidth: 2))
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link,
                                  size: 16, color: AppColors.estab),
                              SizedBox(width: 6),
                              Text('Associar a este estabelecimento',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.estab)),
                            ],
                          ),
                  ),
                ),
              ),
            if (onRemover != null)
              InkWell(
                onTap: onRemover,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_off,
                            size: 16, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text('Remover do estabelecimento',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning)),
                      ],
                    ),
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
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.grey))),
      ]);
}
