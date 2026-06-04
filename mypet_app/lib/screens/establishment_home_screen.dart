import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../services/veterinarian_service.dart';
import '../widgets/mypet_app_bar.dart';
import '../models/veterinarian.dart';
import 'establishment_drivers_screen.dart';

class EstabHomeScreen extends StatefulWidget {
  const EstabHomeScreen({super.key});
  @override
  State<EstabHomeScreen> createState() => _EstabHomeScreenState();
}

class _EstabHomeScreenState extends State<EstabHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) return;

    final estabProvider = context.read<EstablishmentProvider>();
    if (force || estabProvider.establishment == null) {
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

  Future<void> _updateStatus(AppointmentModel booking, String status) async {
    final auth = context.read<AuthProvider>();
    final ok = await context.read<BookingProvider>().updateStatus(
          token: auth.token!,
          bookingId: booking.id,
          status: status,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (status == 'CONFIRMADO' ? 'Agendamento confirmado!' : 'Agendamento recusado')
            : 'Erro ao atualizar agendamento'),
        backgroundColor: ok
            ? (status == 'CONFIRMADO' ? AppColors.success : AppColors.danger)
            : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final estab = context.watch<EstablishmentProvider>();
    final pendentes = booking.pendentes;
    final proximos = booking.confirmados;
    final isVet = estab.establishment?.isVeterinario ?? false;
    final atendeEmergencia = estab.establishment?.atendeEmergencia ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            EstabPurpleHeader(
              pendentes: pendentes.length,
              confirmados: proximos.length,
              avaliacao: estab.establishment?.rating.toStringAsFixed(1) ?? '—',
            ),

            if (isVet && atendeEmergencia)
              Container(
                color: AppColors.danger.withValues(alpha: 0.08),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.emergency,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Modo emergência ativo — você receberá solicitações urgentes',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: const Color(0xFF0EA5E9),
                indicatorWeight: 2,
                labelColor: const Color(0xFF0EA5E9),
                unselectedLabelColor: AppColors.grey,
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 11.5),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400, fontSize: 11.5),
                tabs: const [
                  Tab(height: 40, text: 'Agenda'),
                  Tab(height: 40, text: 'Serviços'),
                  Tab(height: 40, text: 'Motoristas'),
                  Tab(height: 40, text: 'Veterinários'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  RefreshIndicator(
                    onRefresh: () async => _load(),
                    color: AppColors.estab,
                    child: booking.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.estab))
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (pendentes.isNotEmpty) ...[
                                _sectionLabel(
                                    'Aguardando confirmação (${pendentes.length})'),
                                ...pendentes.map((a) => _AgendCard(
                                      appointment: a,
                                      showActions: true,
                                      onConfirmar: () =>
                                          _updateStatus(a, 'CONFIRMADO'),
                                      onRecusar: () =>
                                          _updateStatus(a, 'RECUSADO'),
                                    )),
                                const SizedBox(height: 8),
                              ],
                              if (proximos.isNotEmpty) ...[
                                _sectionLabel('Próximos Agendamentos'),
                                ...proximos
                                    .map((a) => _AgendCard(appointment: a)),
                              ],
                              if (pendentes.isEmpty && proximos.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(32),
                                          ),
                                          child: const Icon(
                                              Icons.calendar_today,
                                              color: AppColors.estab,
                                              size: 30),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('Sem agendamentos',
                                            style: TextStyle(
                                                color: AppColors.dark,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15)),
                                        const SizedBox(height: 4),
                                        const Text(
                                            'Novos pedidos aparecerão aqui',
                                            style: TextStyle(
                                                color: AppColors.grey,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),

                  _ServicosTab(onRetry: () => _load(force: true)),
                  const _MotoristasTab(),
                  const _VeterinarioTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.dark)),
      );
}

class _AgendCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showActions;
  final VoidCallback? onConfirmar;
  final VoidCallback? onRecusar;

  const _AgendCard({
    required this.appointment,
    this.showActions = false,
    this.onConfirmar,
    this.onRecusar,
  });

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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child:
                    const Icon(Icons.pets, color: AppColors.estab, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ap.petName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark)),
                    Text(
                      ap.petBreed.isNotEmpty ? ap.petBreed : ap.serviceName,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          _row(Icons.person_outline,
              ap.userName.isNotEmpty ? ap.userName : 'Tutor'),
          const SizedBox(height: 4),
          _row(Icons.content_cut_outlined, ap.serviceName),
          const SizedBox(height: 4),
          _row(
              Icons.calendar_today_outlined,
              '${ap.date.day.toString().padLeft(2, '0')}/${ap.date.month.toString().padLeft(2, '0')}/${ap.date.year}  ${ap.time}'),
          if (ap.price > 0) ...[
            const SizedBox(height: 4),
            _row(Icons.attach_money, 'R\$ ${ap.price.toStringAsFixed(2)}'),
          ],

          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRecusar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Recusar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Confirmar',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey))),
        ],
      );
}

class _ServicosTab extends StatelessWidget {
  final VoidCallback onRetry;
  const _ServicosTab({required this.onRetry});

  static const _categorias = [
    ('banho', 'Banho'),
    ('tosa', 'Tosa'),
    ('consulta_veterinaria', 'Consulta Veterinária'),
    ('vacinacao', 'Vacinação'),
    ('exames', 'Exames'),
    ('cirurgias', 'Cirurgias'),
    ('internacao', 'Internação'),
    ('emergencia', 'Emergência'),
    ('medicamentos', 'Medicamentos'),
    ('atendimento_domiciliar', 'Atendimento Domiciliar'),
    ('outros', 'Outros'),
  ];

  bool _isVetCategoria(String cat) => const {
        'consulta_veterinaria',
        'vacinacao',
        'exames',
        'cirurgias',
        'internacao',
        'emergencia',
        'medicamentos',
        'atendimento_domiciliar',
      }.contains(cat);

  Future<void> _showAddServico(BuildContext context) async {
    final estab = context.read<EstablishmentProvider>().establishment;
    final isVet = estab?.isVeterinario ?? false;

    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategoria = isVet ? 'consulta_veterinaria' : 'banho';
    bool priceVariable = false;

    final categoriasFiltradas = isVet
        ? _categorias
        : _categorias.where((c) => !_isVetCategoria(c.$1)).toList();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Novo Serviço',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.dark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    controller: nomeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nome *')),
                const SizedBox(height: 8),
                const Text('Categoria',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedCategoria,
                  isExpanded: true,
                  items: categoriasFiltradas
                      .map((c) => DropdownMenuItem(
                            value: c.$1,
                            child: Text(c.$2,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedCategoria = v!),
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: priceVariable,
                      activeColor: AppColors.estab,
                      onChanged: (v) =>
                          setDialogState(() => priceVariable = v!),
                    ),
                    const Text('Preço sob consulta',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
                if (!priceVariable)
                  TextField(
                      controller: precoCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Preço (R\$) *'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true)),
                TextField(
                    controller: durCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Duração (min) *'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeCtrl.text.trim();
                final preco = priceVariable
                    ? 0.0
                    : double.tryParse(
                        precoCtrl.text.replaceAll(',', '.'));
                final dur = int.tryParse(durCtrl.text.trim());

                if (nome.isEmpty ||
                    (!priceVariable && preco == null) ||
                    dur == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Preencha nome, preço e duração'),
                    backgroundColor: AppColors.warning,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }

                Navigator.pop(ctx);

                final auth = context.read<AuthProvider>();
                final ok =
                    await context.read<EstablishmentProvider>().addService(
                          token: auth.token!,
                          name: nome,
                          price: preco ?? 0,
                          durationMinutes: dur,
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          categoria: selectedCategoria,
                          priceVariable: priceVariable,
                        );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Serviço adicionado com sucesso!'
                        : (context
                                .read<EstablishmentProvider>()
                                .error ??
                            'Erro ao salvar serviço')),
                    backgroundColor:
                        ok ? AppColors.success : AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.estab, elevation: 0),
              child: const Text('Salvar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    nomeCtrl.dispose();
    precoCtrl.dispose();
    durCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _confirmDelete(
      BuildContext context, String serviceId, String serviceName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover serviço?'),
        content: Text('Deseja remover o serviço "$serviceName"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, elevation: 0),
            child:
                const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await context.read<EstablishmentProvider>().removeService(
          token: auth.token!,
          serviceId: serviceId,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Serviço removido'
            : (context.read<EstablishmentProvider>().error ??
                'Erro ao remover')),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estab = context.watch<EstablishmentProvider>();
    final services = estab.services;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Serviços Cadastrados',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.dark)),
            ElevatedButton.icon(
              onPressed: estab.establishmentId == null
                  ? null
                  : () => _showAddServico(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Novo',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.estab,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (estab.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.estab),
            ),
          )
        else if (estab.establishment == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.wifi_off,
                      color: AppColors.greyLight, size: 36),
                  const SizedBox(height: 8),
                  const Text('Não foi possível carregar',
                      style: TextStyle(color: AppColors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh,
                        size: 16, color: Colors.white),
                    label: const Text('Tentar novamente',
                        style:
                            TextStyle(color: Colors.white, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.estab,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (services.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.content_cut,
                      color: AppColors.greyLight, size: 36),
                  SizedBox(height: 8),
                  Text('Nenhum serviço cadastrado',
                      style: TextStyle(color: AppColors.grey)),
                  SizedBox(height: 4),
                  Text('Toque em "Novo" para adicionar',
                      style: TextStyle(
                          color: AppColors.greyLight, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...services.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(s.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.dark)),
                              ),
                              if (s.isVeterinary)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('VET',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          if (s.description != null &&
                              s.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(s.description!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey)),
                          ],
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 13, color: AppColors.grey),
                              const SizedBox(width: 4),
                              Text('${s.durationMinutes} min',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.grey)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(s.categoriaLabel,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.estab)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.priceLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.estab,
                          fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          _confirmDelete(context, s.id, s.name),
                      child: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.grey),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

class _MotoristasTab extends StatefulWidget {
  const _MotoristasTab();

  @override
  State<_MotoristasTab> createState() => _MotoristasTabState();
}

class _MotoristasTabState extends State<_MotoristasTab>
    with AutomaticKeepAliveClientMixin {
  List<DriverModel> _motoristas = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final estab = context.read<EstablishmentProvider>();
    if (auth.token == null || estab.establishmentId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      _motoristas = await DriverService.fetchByEstablishment(
        token: auth.token!,
        establishmentId: estab.establishmentId!,
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _desassociar(DriverModel driver) async {
    final auth = context.read<AuthProvider>();
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
            child:
                const Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child:
                const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await DriverService.dissociate(
          token: auth.token!, driverId: driver.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Motorista removido do estabelecimento'),
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
    final auth = context.read<AuthProvider>();
    final estab = context.read<EstablishmentProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => EstabMotoristaBuscarSheet(
        estabId: estab.establishmentId!,
        token: auth.token!,
        onAssociado: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final estab = context.watch<EstablishmentProvider>();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.estab,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Motoristas',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.dark)),
              ElevatedButton.icon(
                onPressed: estab.establishmentId == null
                    ? null
                    : _abrirAdicionar,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Adicionar',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.estab,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.estab),
              ),
            )
          else if (_motoristas.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        color: AppColors.greyLight, size: 36),
                    SizedBox(height: 8),
                    Text('Nenhum motorista associado',
                        style: TextStyle(
                            color: AppColors.grey,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Toque em "Adicionar" para buscar ou cadastrar',
                        style: TextStyle(
                            color: AppColors.greyLight, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ..._motoristas.map((d) => EstabMotoristaCard(
                  driver: d,
                  onRemover: () => _desassociar(d),
                )),
        ],
      ),
    );
  }
}

class _VeterinarioTab extends StatefulWidget {
  const _VeterinarioTab();
  @override
  State<_VeterinarioTab> createState() => _VeterinarioTabState();
}

class _VeterinarioTabState extends State<_VeterinarioTab>
    with AutomaticKeepAliveClientMixin {
  List<VeterinarianModel> _vets = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final estab = context.read<EstablishmentProvider>();
    if (auth.token == null || estab.establishmentId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      _vets = await VeterinarianService.fetchByEstablishment(
        token: auth.token!,
        establishmentId: estab.establishmentId!,
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _desassociar(VeterinarianModel vet) async {
    final auth = context.read<AuthProvider>();
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
            child: const Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await VeterinarianService.dissociate(token: auth.token!, vetId: vet.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veterinário removido do estabelecimento'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _abrirAdicionar() {
    final auth = context.read<AuthProvider>();
    final estab = context.read<EstablishmentProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AdicionarVetSheet(
        estabId: estab.establishmentId!,
        token: auth.token!,
        onAdicionado: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final estab = context.watch<EstablishmentProvider>();
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.estab,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Veterinários',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.dark)),
              ElevatedButton.icon(
                onPressed: estab.establishmentId == null ? null : _abrirAdicionar,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Adicionar',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.estab,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.estab)),
            )
          else if (_vets.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyLight),
              ),
              child: const Center(
                child: Column(children: [
                  Icon(Icons.medical_services_outlined,
                      color: AppColors.greyLight, size: 36),
                  SizedBox(height: 8),
                  Text('Nenhum veterinário associado',
                      style: TextStyle(
                          color: AppColors.grey, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Toque em "Adicionar" para buscar ou cadastrar',
                      style: TextStyle(color: AppColors.greyLight, fontSize: 12)),
                ]),
              ),
            )
          else
            ..._vets.map((v) => _VetCardInline(
                  vet: v,
                  onRemover: () => _desassociar(v),
                )),
        ],
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

  Future<void> _buscar() async {
    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) { setState(() => _erroMsg = 'CPF deve ter 11 dígitos'); return; }
    setState(() { _buscando = true; _encontrado = null; _erroMsg = null; });
    try {
      final v = await VeterinarianService.findByCpf(token: widget.token, cpf: cpf);
      setState(() { _encontrado = v; _erroMsg = v == null ? 'Veterinário não encontrado' : null; });
    } catch (_) {
      setState(() => _erroMsg = 'Erro ao buscar');
    } finally {
      setState(() => _buscando = false);
    }
  }

  Future<void> _associar(VeterinarianModel v) async {
    if (v.isAssociado) { setState(() => _erroMsg = 'Já associado a outro estabelecimento'); return; }
    setState(() => _associando = true);
    try {
      await VeterinarianService.associate(
          token: widget.token, vetId: v.id, establishmentId: widget.estabId);
      if (mounted) {
        Navigator.pop(context);
        widget.onAdicionado();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${v.name} associado!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adicionar Veterinário',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      indicator: BoxDecoration(color: AppColors.estab, borderRadius: BorderRadius.circular(8)),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [Tab(text: 'Buscar por CPF'), Tab(text: 'Cadastrar novo')],
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
                  _BuscarVetTab(
                    cpfCtrl: _cpfCtrl,
                    encontrado: _encontrado,
                    buscando: _buscando,
                    associando: _associando,
                    erroMsg: _erroMsg,
                    onBuscar: _buscar,
                    onAssociar: _associar,
                  ),
                  _CadastrarVetTab(
                    estabId: widget.estabId,
                    token: widget.token,
                    onCadastrado: () { Navigator.pop(context); widget.onAdicionado(); },
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

class _BuscarVetTab extends StatelessWidget {
  final TextEditingController cpfCtrl;
  final VeterinarianModel? encontrado;
  final bool buscando, associando;
  final String? erroMsg;
  final VoidCallback onBuscar;
  final Future<void> Function(VeterinarianModel) onAssociar;

  const _BuscarVetTab({
    required this.cpfCtrl, required this.encontrado, required this.buscando,
    required this.associando, required this.erroMsg,
    required this.onBuscar, required this.onAssociar,
  });

  @override
  Widget build(BuildContext context) {
    InputDecoration dec(String label) => InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.badge, color: AppColors.estab, size: 20),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.estab, width: 2)),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Informe o CPF do veterinário cadastrado no sistema.',
            style: TextStyle(fontSize: 13, color: AppColors.grey)),
        const SizedBox(height: 16),
        TextFormField(
          controller: cpfCtrl,
          keyboardType: TextInputType.number,
          decoration: dec('CPF do veterinário'),
          onFieldSubmitted: (_) => onBuscar(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: buscando ? null : onBuscar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.estab, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: buscando
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Buscar',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        if (erroMsg != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10)),
            child: Text(erroMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
        ],
        if (encontrado != null) ...[
          const SizedBox(height: 16),
          _VetCardInline(
            vet: encontrado!,
            onAssociar: encontrado!.isAssociado ? null : () => onAssociar(encontrado!),
            associando: associando,
          ),
        ],
      ],
    );
  }
}

class _CadastrarVetTab extends StatefulWidget {
  final String estabId, token;
  final VoidCallback onCadastrado;
  const _CadastrarVetTab({required this.estabId, required this.token, required this.onCadastrado});
  @override
  State<_CadastrarVetTab> createState() => _CadastrarVetTabState();
}

class _CadastrarVetTabState extends State<_CadastrarVetTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _crmvCtrl = TextEditingController();
  final _espCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureSenha = true;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _cpfCtrl, _emailCtrl, _senhaCtrl, _crmvCtrl, _espCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text, phone: _phoneCtrl.text.trim(),
        cpf: _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''), role: 'VETERINARIO',
      );
      final vet = await VeterinarianService.register(
        token: widget.token, establishmentId: widget.estabId,
        name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(),
        cpf: _cpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
        crmv: _crmvCtrl.text.trim().toUpperCase(),
        especialidade: _espCtrl.text.trim().isEmpty ? null : _espCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${vet.name} cadastrado e associado!'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
      ));
      widget.onCadastrado();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _f(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, TextInputType keyboard = TextInputType.text,
      TextCapitalization caps = TextCapitalization.words,
      String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl, keyboardType: keyboard, textCapitalization: caps,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.estab, size: 20),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.greyLight)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.greyLight)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.estab, width: 2)),
        ),
        validator: validator ?? (required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null : null),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _f(_nameCtrl, 'Nome completo', Icons.person, required: true),
          const SizedBox(height: 10),
          _f(_phoneCtrl, 'Telefone', Icons.phone, required: true, keyboard: TextInputType.phone),
          const SizedBox(height: 10),
          _f(_cpfCtrl, 'CPF', Icons.badge, required: true, keyboard: TextInputType.number,
              validator: (v) => (v?.replaceAll(RegExp(r'\D'), '') ?? '').length != 11
                  ? 'CPF deve ter 11 dígitos' : null),
          const SizedBox(height: 10),
          _f(_emailCtrl, 'E-mail', Icons.email_outlined, required: true,
              keyboard: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null),
          const SizedBox(height: 10),
          TextFormField(
            controller: _senhaCtrl, obscureText: _obscureSenha,
            decoration: InputDecoration(
              labelText: 'Senha (mín. 6 caracteres)',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.estab, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.grey, size: 20),
                onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
              ),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.greyLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.greyLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.estab, width: 2)),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 10),
          _f(_crmvCtrl, 'CRMV (ex: SP-12345)', Icons.verified,
              required: true, caps: TextCapitalization.characters),
          const SizedBox(height: 10),
          _f(_espCtrl, 'Especialidade (opcional)', Icons.medical_services_outlined),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.estab, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Cadastrar e Associar',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VetCardInline extends StatelessWidget {
  final VeterinarianModel vet;
  final VoidCallback? onRemover;
  final VoidCallback? onAssociar;
  final bool associando;

  const _VetCardInline({
    required this.vet, this.onRemover, this.onAssociar, this.associando = false,
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
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.medical_services_outlined,
                      color: AppColors.estab, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vet.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
                      Text('${vet.especialidade ?? 'Clínico geral'} · CRMV: ${vet.crmv}',
                          style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                      Text(vet.phone,
                          style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                    ],
                  ),
                ),
                if (vet.isAssociado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20)),
                    child: const Text('Associado',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                  ),
              ],
            ),
          ),
          if (onRemover != null || onAssociar != null) ...[
            const Divider(height: 1, color: AppColors.greyLight),
            if (onAssociar != null)
              InkWell(
                onTap: associando ? null : onAssociar,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Center(
                    child: associando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: AppColors.estab, strokeWidth: 2))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.link, size: 16, color: AppColors.estab),
                            SizedBox(width: 6),
                            Text('Associar a este estabelecimento',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                    color: AppColors.estab)),
                          ]),
                  ),
                ),
              ),
            if (onRemover != null)
              InkWell(
                onTap: onRemover,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.link_off, size: 16, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text('Remover do estabelecimento',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.warning)),
                    ]),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
