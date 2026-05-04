import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/establishment.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EstabHomeScreen extends StatefulWidget {
  const EstabHomeScreen({super.key});
  @override
  State<EstabHomeScreen> createState() => _EstabHomeScreenState();
}

class _EstabHomeScreenState extends State<EstabHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  EstablishmentModel? _establishment;
  List<Map<String, dynamic>> _agendamentos = [];
  bool _loadingEstab = true;
  bool _loadingBookings = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().user?.id;
    final token = context.read<AuthProvider>().token;
    if (userId == null) return;

    try {
      final data = await ApiService.get(
        '/establishments/owner/$userId',
        token: token,
      );
      final list = data as List<dynamic>;
      if (list.isNotEmpty && mounted) {
        final estab = EstablishmentModel.fromJson(
            list.first as Map<String, dynamic>);
        setState(() {
          _establishment = estab;
          _loadingEstab = false;
        });
        await _loadBookings(estab.id, token);
      } else if (mounted) {
        setState(() => _loadingEstab = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEstab = false);
    }
  }

  Future<void> _loadBookings(String estabId, String? token) async {
    try {
      final data = await ApiService.get(
        '/bookings/establishment/$estabId',
        token: token,
      );
      if (mounted) {
        setState(() {
          _agendamentos = (data as List<dynamic>)
              .map((b) => b as Map<String, dynamic>)
              .toList();
          _loadingBookings = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBookings = false);
    }
  }

  Future<void> _updateStatus(String bookingId, String status) async {
    final token = context.read<AuthProvider>().token;
    try {
      await ApiService.patch(
        '/bookings/$bookingId/status',
        {'status': status},
        token: token,
      );
      setState(() {
        final idx = _agendamentos.indexWhere((b) => b['id'] == bookingId);
        if (idx >= 0) _agendamentos[idx]['status'] = status;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'CONFIRMADO'
              ? 'Agendamento confirmado!'
              : 'Agendamento recusado.'),
          backgroundColor:
              status == 'CONFIRMADO' ? AppColors.success : AppColors.danger,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao atualizar status'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _addService(String name, double price, int duration) async {
    if (_establishment == null) return;
    final token = context.read<AuthProvider>().token;
    try {
      final data = await ApiService.post(
        '/establishments/${_establishment!.id}/services',
        {'name': name, 'price': price, 'durationMinutes': duration},
        token: token,
      );
      final updated = EstablishmentModel.fromJson(data as Map<String, dynamic>);
      setState(() => _establishment = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao adicionar serviço'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  int get _pendentes =>
      _agendamentos.where((a) => a['status'] == 'PENDENTE').length;
  int get _confirmados =>
      _agendamentos.where((a) => a['status'] == 'CONFIRMADO').length;
  int get _concluidos =>
      _agendamentos.where((a) => a['status'] == 'CONCLUIDO').length;
  double get _receitaTotal => _agendamentos
      .where((a) => a['status'] == 'CONCLUIDO')
      .fold(0.0, (s, a) => s + ((a['price'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    final pendentes =
        _agendamentos.where((a) => a['status'] == 'PENDENTE').toList();
    final proximos =
        _agendamentos.where((a) => a['status'] == 'CONFIRMADO').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chevron_left, color: Colors.transparent),
                      const Spacer(),
                      Image.asset('assets/images/logo.png',
                          height: 32,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      ),
                    ],
                  ),
                  if (_establishment != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _establishment!.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      _statCard('Pendentes', '$_pendentes',
                          Icons.schedule, Colors.white),
                      const SizedBox(width: 10),
                      _statCard('Confirmados', '$_confirmados',
                          Icons.check_circle_outline, Colors.white),
                      const SizedBox(width: 10),
                      _statCard(
                          'Avaliação',
                          _establishment != null
                              ? _establishment!.rating.toStringAsFixed(1)
                              : '—',
                          Icons.star_outline,
                          Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Agendamentos'),
                  Tab(text: 'Serviços'),
                  Tab(text: 'Estatísticas'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _loadingBookings
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _agendamentos.isEmpty
                          ? const Center(
                              child: Text('Nenhum agendamento ainda',
                                  style: TextStyle(color: AppColors.grey)))
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (pendentes.isNotEmpty) ...[
                                  _sectionLabel(
                                      'Aguardando Confirmação (${pendentes.length})'),
                                  ...pendentes.map((a) => _AgendCard(
                                        booking: a,
                                        showActions: true,
                                        onConfirmar: () => _updateStatus(
                                            a['id'], 'CONFIRMADO'),
                                        onRecusar: () => _updateStatus(
                                            a['id'], 'RECUSADO'),
                                      )),
                                  const SizedBox(height: 8),
                                ],
                                if (proximos.isNotEmpty) ...[
                                  _sectionLabel('Próximos Agendamentos'),
                                  ...proximos.map(
                                      (a) => _AgendCard(booking: a)),
                                ],
                              ],
                            ),
                  _ServicosTab(
                    establishment: _establishment,
                    loading: _loadingEstab,
                    onAddService: _addService,
                  ),
                  _EstatisticasTab(
                    agendamentos: _agendamentos,
                    loading: _loadingBookings,
                    pendentes: _pendentes,
                    confirmados: _confirmados,
                    concluidos: _concluidos,
                    receitaTotal: _receitaTotal,
                    avgRating: _establishment?.rating ?? 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8), fontSize: 10)),
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
  final Map<String, dynamic> booking;
  final bool showActions;
  final VoidCallback? onConfirmar;
  final VoidCallback? onRecusar;

  const _AgendCard({
    required this.booking,
    this.showActions = false,
    this.onConfirmar,
    this.onRecusar,
  });

  Color get _statusColor {
    switch (booking['status'] as String? ?? '') {
      case 'CONFIRMADO':
        return AppColors.success;
      case 'RECUSADO':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final petName = booking['petName'] as String? ?? '—';
    final tutorName = booking['userName'] as String? ?? '—';
    final servico = booking['serviceName'] as String? ?? '—';
    final status = booking['status'] as String? ?? 'PENDENTE';
    final scheduledAt = _formatDate(booking['scheduledAt'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
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
                child: const Icon(Icons.pets,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(petName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          _row(Icons.person_outline, 'Tutor: $tutorName'),
          const SizedBox(height: 3),
          _row(Icons.content_cut, servico),
          const SizedBox(height: 3),
          _row(Icons.calendar_today_outlined, scheduledAt),
          if (showActions) ...[
            const SizedBox(height: 10),
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
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Recusar'),
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
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Confirmar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(status,
            style: TextStyle(
                color: _statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 13, color: AppColors.grey),
          const SizedBox(width: 4),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey))),
        ],
      );
}

class _EstatisticasTab extends StatelessWidget {
  final List<Map<String, dynamic>> agendamentos;
  final bool loading;
  final int pendentes;
  final int confirmados;
  final int concluidos;
  final double receitaTotal;
  final double avgRating;

  const _EstatisticasTab({
    required this.agendamentos,
    required this.loading,
    required this.pendentes,
    required this.confirmados,
    required this.concluidos,
    required this.receitaTotal,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final recusados =
        agendamentos.where((a) => a['status'] == 'RECUSADO').length;
    final total = agendamentos.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Resumo Geral',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.dark)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _StatBox('Agendamentos', '$total',
                  Icons.calendar_month, AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox('Concluídos', '$concluidos',
                  Icons.check_circle_outline, AppColors.success)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _StatBox('Pendentes', '$pendentes',
                  Icons.schedule, AppColors.warning)),
          const SizedBox(width: 10),
          Expanded(
              child: _StatBox('Recusados', '$recusados',
                  Icons.cancel_outlined, AppColors.danger)),
        ]),
        const SizedBox(height: 20),
        const Text('Financeiro',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.dark)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.attach_money,
                    color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Receita (serviços concluídos)',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.grey)),
                  Text(
                    'R\$ ${receitaTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: AppColors.dark),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Qualidade',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.dark)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFC107), size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Avaliação Média',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.grey)),
                  Text(
                    avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: AppColors.dark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.dark)),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.grey)),
        ],
      ),
    );
  }
}

class _ServicosTab extends StatefulWidget {
  final EstablishmentModel? establishment;
  final bool loading;
  final Future<void> Function(String name, double price, int duration)
      onAddService;

  const _ServicosTab({
    required this.establishment,
    required this.loading,
    required this.onAddService,
  });

  @override
  State<_ServicosTab> createState() => _ServicosTabState();
}

class _ServicosTabState extends State<_ServicosTab> {
  void _showAddServico(BuildContext context) {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Serviço'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome')),
            TextField(
                controller: precoCtrl,
                decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                keyboardType: TextInputType.number),
            TextField(
                controller: durCtrl,
                decoration: const InputDecoration(labelText: 'Duração (min)'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeCtrl.text.isNotEmpty &&
                  precoCtrl.text.isNotEmpty &&
                  durCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                await widget.onAddService(
                  nomeCtrl.text,
                  double.tryParse(precoCtrl.text) ?? 0,
                  int.tryParse(durCtrl.text) ?? 0,
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child:
                const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final services = widget.establishment?.services ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Serviços Cadastrados',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.dark)),
            ElevatedButton.icon(
              onPressed: () => _showAddServico(context),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Novo',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('Nenhum serviço cadastrado',
                  style: TextStyle(color: AppColors.grey)),
            ),
          )
        else
          ...services.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.greyLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.dark)),
                          Text('Duração: ${s.durationMinutes} min',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.grey)),
                        ],
                      ),
                    ),
                    Text(
                      'R\$ ${s.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
