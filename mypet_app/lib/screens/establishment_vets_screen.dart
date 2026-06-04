import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/veterinarian.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/auth_service.dart';
import '../services/veterinarian_service.dart';
import '../widgets/mypet_app_bar.dart';

class EstabVeterinariosScreen extends StatefulWidget {
  const EstabVeterinariosScreen({super.key});

  @override
  State<EstabVeterinariosScreen> createState() => _EstabVeterinariosScreenState();
}

class _EstabVeterinariosScreenState extends State<EstabVeterinariosScreen> {
  List<VeterinarianModel> _vets = [];
  bool _loading = true;
  String? _estabId;
  String? _token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final estabProvider = context.read<EstablishmentProvider>();
    if (auth.token == null) return;
    _token = auth.token;

    if (estabProvider.establishmentId == null) {
      await estabProvider.loadByOwner(
        token: auth.token!,
        ownerId: auth.user!.id,
        ownerName: auth.user!.name,
        ownerPhone: auth.user!.phone,
      );
    }
    _estabId = estabProvider.establishmentId;
    if (_estabId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      _vets = await VeterinarianService.fetchByEstablishment(
        token: _token!,
        establishmentId: _estabId!,
      );
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _remover(VeterinarianModel vet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover veterinário?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Deseja remover ${vet.name} deste estabelecimento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Remover',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await VeterinarianService.dissociate(token: _token!, vetId: vet.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veterinário removido do estabelecimento'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    }
  }

  void _abrirAdicionar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AdicionarVetSheet(
        estabId: _estabId!,
        token: _token!,
        onAdicionado: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _estabId == null ? null : _abrirAdicionar,
        backgroundColor: AppColors.estab,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Adicionar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.estab))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.estab,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  const Text('Veterinários',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark)),
                  const SizedBox(height: 4),
                  const Text(
                    'Veterinários associados a este estabelecimento.',
                    style: TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                  const SizedBox(height: 20),
                  if (_vets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.medical_services_outlined,
                              size: 48, color: AppColors.greyLight),
                          SizedBox(height: 10),
                          Text('Nenhum veterinário associado',
                              style: TextStyle(
                                  color: AppColors.dark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          SizedBox(height: 4),
                          Text(
                            'Toque em "Adicionar" para buscar ou cadastrar um veterinário.',
                            style: TextStyle(
                                color: AppColors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._vets.map((v) => _VetCard(
                          vet: v,
                          onRemover: () => _remover(v),
                        )),
                ],
              ),
            ),
    );
  }
}

class _AdicionarVetSheet extends StatefulWidget {
  final String estabId;
  final String token;
  final VoidCallback onAdicionado;
  const _AdicionarVetSheet({
    required this.estabId,
    required this.token,
    required this.onAdicionado,
  });

  @override
  State<_AdicionarVetSheet> createState() => _AdicionarVetSheetState();
}

class _AdicionarVetSheetState extends State<_AdicionarVetSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _cpfCtrl = TextEditingController();
  VeterinarianModel? _encontrado;
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
      final vet = await VeterinarianService.findByCpf(
          token: widget.token, cpf: cpf);
      setState(() {
        _encontrado = vet;
        _erroMsg = vet == null ? 'Veterinário não encontrado' : null;
      });
    } catch (_) {
      setState(() => _erroMsg = 'Erro ao buscar veterinário');
    } finally {
      setState(() => _buscando = false);
    }
  }

  Future<void> _associar(VeterinarianModel vet) async {
    if (vet.isAssociado) {
      setState(() =>
          _erroMsg = 'Veterinário já está associado a outro estabelecimento');
      return;
    }
    setState(() => _associando = true);
    try {
      await VeterinarianService.associate(
        token: widget.token,
        vetId: vet.id,
        establishmentId: widget.estabId,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onAdicionado();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vet.name} associado com sucesso!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _erroMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _associando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  const Text('Adicionar Veterinário',
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
                    estabId: widget.estabId,
                    token: widget.token,
                    onCadastrado: () {
                      Navigator.pop(context);
                      widget.onAdicionado();
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
  final VeterinarianModel? encontrado;
  final bool buscando;
  final bool associando;
  final String? erroMsg;
  final VoidCallback onBuscar;
  final Future<void> Function(VeterinarianModel) onAssociar;

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
          'O veterinário deve estar cadastrado no sistema. Informe o CPF para localizá-lo.',
          style: TextStyle(fontSize: 13, color: AppColors.grey),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: cpfCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'CPF do veterinário',
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          _VetCard(
            vet: encontrado!,
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
  final String estabId;
  final String token;
  final VoidCallback onCadastrado;
  const _CadastrarTab({
    required this.estabId,
    required this.token,
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
  final _crmvCtrl = TextEditingController();
  final _especialidadeCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureSenha = true;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _phoneCtrl, _cpfCtrl, _emailCtrl,
      _senhaCtrl, _crmvCtrl, _especialidadeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text,
        phone: _phoneCtrl.text.trim(),
        cpf: _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
        role: 'VETERINARIO',
      );
      final vet = await VeterinarianService.register(
        token: widget.token,
        establishmentId: widget.estabId,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cpf: _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
        crmv: _crmvCtrl.text.trim().toUpperCase(),
        especialidade: _especialidadeCtrl.text.trim().isEmpty
            ? null
            : _especialidadeCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vet.name} cadastrado e associado!'),
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
          _field(_crmvCtrl, 'CRMV (ex: SP-12345)', Icons.verified,
              required: true, caps: TextCapitalization.characters),
          const SizedBox(height: 10),
          _field(_especialidadeCtrl, 'Especialidade (opcional)',
              Icons.medical_services_outlined),
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
            borderSide:
                const BorderSide(color: AppColors.estab, width: 2),
          ),
        ),
        validator: validator ??
            (required
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
                : null),
      );
}

class _VetCard extends StatelessWidget {
  final VeterinarianModel vet;
  final VoidCallback? onRemover;
  final VoidCallback? onAssociar;
  final bool associando;

  const _VetCard({
    required this.vet,
    this.onRemover,
    this.onAssociar,
    this.associando = false,
  });

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
                        color: vet.isAtivo
                            ? AppColors.primaryLight
                            : AppColors.greyLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.medical_services_outlined,
                          color: vet.isAtivo
                              ? AppColors.estab
                              : AppColors.grey,
                          size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vet.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.dark)),
                          Text(
                            vet.especialidade ?? 'Clínico geral',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (vet.isAssociado)
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
                _row(Icons.verified_outlined, 'CRMV: ${vet.crmv}'),
                const SizedBox(height: 3),
                _row(Icons.phone_outlined, vet.phone),
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
