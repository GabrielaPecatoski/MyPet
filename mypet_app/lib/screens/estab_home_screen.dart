import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/establishment_provider.dart';
import '../widgets/mypet_app_bar.dart';

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
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
        content: Text(status == 'CONFIRMADO'
            ? 'Agendamento confirmado!'
            : 'Agendamento recusado'),
        backgroundColor:
            status == 'CONFIRMADO' ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final estab = context.watch<EstablishmentProvider>();
    final pendentes = booking.pendentes;
    final proximos = booking.confirmados;

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

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Agendamentos'),
                  Tab(text: 'Serviços'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // ── Aba Agendamentos ──────────────────────────
                  RefreshIndicator(
                    onRefresh: () async => _load(),
                    color: AppColors.primary,
                    child: booking.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
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
                                              color: AppColors.primary,
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

                  // ── Aba Serviços ──────────────────────────────
                  const _ServicosTab(),
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

// ── Card de agendamento ──────────────────────────────────────────
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
                    const Icon(Icons.pets, color: AppColors.primary, size: 22),
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

// ── Aba de Serviços (dados reais do banco) ──────────────────────
class _ServicosTab extends StatelessWidget {
  const _ServicosTab();

  Future<void> _showAddServico(BuildContext context) async {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Novo Serviço',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.dark)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome *')),
              TextField(
                  controller: precoCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Preço (R\$) *'),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true)),
              TextField(
                  controller: durCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Duração (min) *'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Descrição (opcional)')),
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
              final preco = double.tryParse(
                  precoCtrl.text.replaceAll(',', '.'));
              final dur = int.tryParse(durCtrl.text.trim());

              if (nome.isEmpty || preco == null || dur == null) {
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
                        price: preco,
                        durationMinutes: dur,
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Serviço adicionado com sucesso!'
                      : (context.read<EstablishmentProvider>().error ??
                          'Erro ao salvar serviço')),
                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, elevation: 0),
            child:
                const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
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
              onPressed:
                  estab.establishmentId == null
                      ? null
                      : () => _showAddServico(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Novo',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
              child:
                  CircularProgressIndicator(color: AppColors.primary),
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
                  Icon(Icons.content_cut, color: AppColors.greyLight, size: 36),
                  SizedBox(height: 8),
                  Text('Nenhum serviço cadastrado',
                      style: TextStyle(color: AppColors.grey)),
                  SizedBox(height: 4),
                  Text('Toque em "Novo" para adicionar',
                      style: TextStyle(color: AppColors.greyLight, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...services.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.dark)),
                          if (s.description != null &&
                              s.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(s.description!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.grey)),
                          ],
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 13, color: AppColors.grey),
                              const SizedBox(width: 4),
                              Text('${s.durationMinutes} min',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'R\$ ${s.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, s.id, s.name),
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
