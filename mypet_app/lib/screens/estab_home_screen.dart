import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';

class _Agendamento {
  final String id;
  final String petName;
  final String petBreed;
  final String tutorName;
  final String tutorPhone;
  final String servico;
  final String data;
  final String hora;
  String status;
  _Agendamento({
    required this.id,
    required this.petName,
    required this.petBreed,
    required this.tutorName,
    required this.tutorPhone,
    required this.servico,
    required this.data,
    required this.hora,
    required this.status,
  });
}

class EstabHomeScreen extends StatefulWidget {
  const EstabHomeScreen({super.key});
  @override
  State<EstabHomeScreen> createState() => _EstabHomeScreenState();
}

class _EstabHomeScreenState extends State<EstabHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final List<_Agendamento> _agendamentos = [
    _Agendamento(
      id: '1', petName: 'Luna', petBreed: 'Siamês',
      tutorName: 'João Silva', tutorPhone: '(11) 99999-9999',
      servico: 'Consulta Veterinária',
      data: '2026-03-20', hora: '10:30', status: 'PENDENTE',
    ),
    _Agendamento(
      id: '2', petName: 'Rex', petBreed: 'Golden Retriever',
      tutorName: 'João Silva', tutorPhone: '(11) 99999-9999',
      servico: 'Tosa',
      data: '2026-03-20', hora: '15:30', status: 'PENDENTE',
    ),
    _Agendamento(
      id: '3', petName: 'Rex', petBreed: 'Golden Retriever',
      tutorName: 'João Silva', tutorPhone: '(11) 99999-9999',
      servico: 'Banho e Tosa',
      data: '2026-03-18', hora: '14:00', status: 'CONFIRMADO',
    ),
    _Agendamento(
      id: '4', petName: 'Mel', petBreed: 'Poodle',
      tutorName: 'Maria Costa', tutorPhone: '(11) 98888-7777',
      servico: 'Banho',
      data: '2026-03-21', hora: '09:00', status: 'CONFIRMADO',
    ),
    _Agendamento(
      id: '5', petName: 'Thor', petBreed: 'Labrador',
      tutorName: 'Carlos Souza', tutorPhone: '(11) 97777-6666',
      servico: 'Tosa',
      data: '2026-03-22', hora: '11:00', status: 'PENDENTE',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int get _pendentes =>
      _agendamentos.where((a) => a.status == 'PENDENTE').length;
  int get _confirmados =>
      _agendamentos.where((a) => a.status == 'CONFIRMADO').length;

  void _confirmar(_Agendamento ag) {
    setState(() => ag.status = 'CONFIRMADO');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Agendamento confirmado!'),
        backgroundColor: AppColors.success));
  }

  void _recusar(_Agendamento ag) {
    setState(() => ag.status = 'RECUSADO');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Agendamento recusado.'),
        backgroundColor: AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final pendentes =
        _agendamentos.where((a) => a.status == 'PENDENTE').toList();
    final proximos =
        _agendamentos.where((a) => a.status == 'CONFIRMADO').toList();

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
                      const Icon(Icons.chevron_left,
                          color: Colors.transparent),
                      const Spacer(),
                      Image.asset('assets/images/logo.png',
                          height: 32, color: Colors.white,
                          colorBlendMode: BlendMode.srcIn),
                      const Spacer(),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child: const Icon(Icons.person,
                            size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard('Pendentes', '$_pendentes',
                          Icons.schedule, Colors.white),
                      const SizedBox(width: 10),
                      _statCard('Confirmados', '$_confirmados',
                          Icons.check_circle_outline, Colors.white),
                      const SizedBox(width: 10),
                      _statCard('Avaliação', '4.6',
                          Icons.star_outline, Colors.white),
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
                tabs: const [Tab(text: 'Agendamentos'), Tab(text: 'Serviços')],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (pendentes.isNotEmpty) ...[
                        _sectionLabel('Aguardando Confirmação (${pendentes.length})'),
                        ...pendentes.map((a) => _AgendCard(
                              ag: a,
                              showActions: true,
                              onConfirmar: () => _confirmar(a),
                              onRecusar: () => _recusar(a),
                            )),
                        const SizedBox(height: 8),
                      ],
                      if (proximos.isNotEmpty) ...[
                        _sectionLabel('Próximos Agendamentos'),
                        ...proximos.map((a) => _AgendCard(ag: a)),
                      ],
                    ],
                  ),
                  _ServicosTab(nomeEstab: user?.name ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
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
                style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10)),
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
  final _Agendamento ag;
  final bool showActions;
  final VoidCallback? onConfirmar;
  final VoidCallback? onRecusar;

  const _AgendCard({
    required this.ag,
    this.showActions = false,
    this.onConfirmar,
    this.onRecusar,
  });

  Color get _statusColor {
    switch (ag.status) {
      case 'CONFIRMADO': return AppColors.success;
      case 'RECUSADO': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.pets, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ag.petName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(ag.petBreed,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey)),
                  ],
                ),
              ),
              _statusChip(),
            ],
          ),
          const SizedBox(height: 8),
          _row(Icons.person_outline, 'Tutor: ${ag.tutorName}'),
          const SizedBox(height: 3),
          _row(Icons.content_cut, ag.servico),
          const SizedBox(height: 3),
          _row(Icons.phone_outlined, ag.tutorPhone),
          const SizedBox(height: 3),
          _row(Icons.calendar_today_outlined, '${ag.data}  ${ag.hora}'),
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

  Widget _statusChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(ag.status,
            style: TextStyle(
                color: _statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  Widget _row(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 13, color: AppColors.grey),
          const SizedBox(width: 4),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 12, color: AppColors.grey))),
        ],
      );
}

class _ServicosTab extends StatefulWidget {
  final String nomeEstab;
  const _ServicosTab({required this.nomeEstab});
  @override
  State<_ServicosTab> createState() => _ServicosTabState();
}

class _ServicosTabState extends State<_ServicosTab> {
  final _servicos = [
    {'nome': 'Banho', 'preco': 'R\$ 50,00', 'duracao': '60 min'},
    {'nome': 'Tosa', 'preco': 'R\$ 80,00', 'duracao': '90 min'},
    {'nome': 'Banho e Tosa', 'preco': 'R\$ 80,00', 'duracao': '120 min'},
    {'nome': 'Consulta Veterinária', 'preco': 'R\$ 120,00', 'duracao': '45 min'},
    {'nome': 'Vacinação', 'preco': 'R\$ 60,00', 'duracao': '20 min'},
  ];

  @override
  Widget build(BuildContext context) {
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
        ..._servicos.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        Text(s['nome']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.dark)),
                        Text('Duração: ${s['duracao']}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.grey)),
                      ],
                    ),
                  ),
                  Text(s['preco']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14)),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.grey),
                ],
              ),
            )),
      ],
    );
  }

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
            onPressed: () {
              if (nomeCtrl.text.isNotEmpty) {
                setState(() {
                  _servicos.add({
                    'nome': nomeCtrl.text,
                    'preco': 'R\$ ${precoCtrl.text}',
                    'duracao': '${durCtrl.text} min',
                  });
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
