import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/mypet_app_bar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Mock data
  final _usuarios = [
    {'nome': 'João Silva', 'email': 'joao@mypet.com', 'role': 'CLIENTE', 'pets': '2', 'agendamentos': '5'},
    {'nome': 'Maria Costa', 'email': 'maria@mypet.com', 'role': 'CLIENTE', 'pets': '1', 'agendamentos': '3'},
    {'nome': 'Carlos Souza', 'email': 'carlos@mypet.com', 'role': 'CLIENTE', 'pets': '3', 'agendamentos': '7'},
    {'nome': 'Ana Lima', 'email': 'ana@mypet.com', 'role': 'CLIENTE', 'pets': '1', 'agendamentos': '2'},
    {'nome': 'Paulo R.', 'email': 'paulo@mypet.com', 'role': 'CLIENTE', 'pets': '2', 'agendamentos': '4'},
    {'nome': 'Admin MyPet', 'email': 'admin@mypet.com', 'role': 'ADMIN', 'pets': '0', 'agendamentos': '0'},
    {'nome': 'Pet Shop Amor & Carinho', 'email': 'petshop@mypet.com', 'role': 'VENDEDOR', 'pets': '0', 'agendamentos': '0'},
  ];

  final _estabelecimentos = [
    {
      'nome': 'Pet Shop Amor & Carinho',
      'tipo': 'Pet Shop',
      'endereco': 'Rua das Flores, 123 — Vila Nova',
      'telefone': '(11) 3456-7890',
      'nota': '4.8',
      'servicos': '3',
      'agendamentos': '48',
    },
    {
      'nome': 'Clínica Veterinária Vida Animal',
      'tipo': 'Clínica Veterinária',
      'endereco': 'Av. Principal, 456 — Jardim das Flores',
      'telefone': '(11) 3456-1884',
      'nota': '4.3',
      'servicos': '5',
      'agendamentos': '32',
    },
    {
      'nome': 'PetCare Express',
      'tipo': 'Pet Shop',
      'endereco': 'Rua Nova, 789 — Vila Nova',
      'telefone': '(11) 3456-1952',
      'nota': '4.5',
      'servicos': '2',
      'agendamentos': '21',
    },
  ];

  final _reclamacoes = [
    {'usuario': 'Carlos M.', 'estab': 'Pet Shop Amor & Carinho', 'assunto': 'Atraso no atendimento', 'data': '2026-02-10', 'status': 'RESPONDIDA'},
    {'usuario': 'Paula T.', 'estab': 'PetCare Express', 'assunto': 'Serviço incompleto', 'data': '2026-03-01', 'status': 'PENDENTE'},
    {'usuario': 'Roberto A.', 'estab': 'Clínica Vida Animal', 'assunto': 'Cobrança indevida', 'data': '2026-03-05', 'status': 'PENDENTE'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MypetAppBar(
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats cards ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _statCard('Usuários', '16', Icons.people_outlined,
                        const Color(0xFF4285F4)),
                    const SizedBox(width: 12),
                    _statCard('Estabelecimentos', '3', Icons.store_outlined,
                        const Color(0xFF34A853)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statCard('Agendamentos', '48', Icons.calendar_month_outlined,
                        const Color(0xFFFBBC04)),
                    const SizedBox(width: 12),
                    _statCard('Avaliação Média', '4.7', Icons.star_outline,
                        const Color(0xFFEA4335)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Tabs ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Reclamações'),
                Tab(text: 'Usuários'),
                Tab(text: 'Estabelecimentos'),
                Tab(text: 'Estatísticas'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _ReclamacoesTab(reclamacoes: _reclamacoes),
                _UsuariosTab(usuarios: _usuarios),
                _EstabelecimentosTab(estabelecimentos: _estabelecimentos),
                const _EstatisticasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Aba Reclamações ───────────────────────────────────────────────
class _ReclamacoesTab extends StatelessWidget {
  final List<Map<String, String>> reclamacoes;
  const _ReclamacoesTab({required this.reclamacoes});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reclamacoes.length,
      itemBuilder: (ctx, i) {
        final r = reclamacoes[i];
        final isPendente = r['status'] == 'PENDENTE';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPendente
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : AppColors.greyLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(r['assunto']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.dark)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPendente
                          ? AppColors.warning.withValues(alpha: 0.12)
                          : AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(r['status']!,
                        style: TextStyle(
                            color: isPendente
                                ? AppColors.warning
                                : AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${r['usuario']} → ${r['estab']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              Text(r['data']!,
                  style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              if (isPendente) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                        child: const Text('Remover'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Resolver',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Aba Usuários ──────────────────────────────────────────────────
class _UsuariosTab extends StatelessWidget {
  final List<Map<String, String>> usuarios;
  const _UsuariosTab({required this.usuarios});

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN': return AppColors.danger;
      case 'VENDEDOR': return const Color(0xFF4285F4);
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: usuarios.length,
      itemBuilder: (ctx, i) {
        final u = usuarios[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _roleColor(u['role']!).withValues(alpha: 0.12),
                child: Text(u['nome']![0],
                    style: TextStyle(
                        color: _roleColor(u['role']!),
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['nome']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(u['email']!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey)),
                    if (u['role'] == 'CLIENTE')
                      Text('${u['pets']} pets · ${u['agendamentos']} agendamentos',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor(u['role']!).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(u['role']!,
                    style: TextStyle(
                        color: _roleColor(u['role']!),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Aba Estabelecimentos ──────────────────────────────────────────
class _EstabelecimentosTab extends StatelessWidget {
  final List<Map<String, String>> estabelecimentos;
  const _EstabelecimentosTab({required this.estabelecimentos});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: estabelecimentos.length,
      itemBuilder: (ctx, i) {
        final e = estabelecimentos[i];
        final isPetShop = e['tipo'] == 'Pet Shop';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                        isPetShop ? Icons.pets : Icons.local_hospital,
                        color: AppColors.primary,
                        size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['nome']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(e['tipo']!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: Color(0xFFFFC107)),
                      Text(e['nota']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.grey),
                const SizedBox(width: 3),
                Expanded(
                    child: Text(e['endereco']!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey))),
              ]),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chip('${e['servicos']} serv.', AppColors.primary),
                  const SizedBox(width: 6),
                  _chip('${e['agendamentos']} agend.', AppColors.success),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ── Aba Estatísticas ──────────────────────────────────────────────
class _EstatisticasTab extends StatelessWidget {
  const _EstatisticasTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _chartCard('Agendamentos por mês', [
          _BarData('Jan', 28, AppColors.primary),
          _BarData('Fev', 35, AppColors.primary),
          _BarData('Mar', 48, AppColors.primary),
          _BarData('Abr', 42, AppColors.greyLight),
          _BarData('Mai', 50, AppColors.greyLight),
        ]),
        const SizedBox(height: 12),
        _pieCard('Distribuição de Serviços', [
          {'label': 'Banho', 'valor': '38%', 'color': AppColors.primary},
          {'label': 'Tosa', 'valor': '25%', 'color': AppColors.warning},
          {'label': 'Banho e Tosa', 'valor': '22%', 'color': AppColors.success},
          {'label': 'Consulta', 'valor': '15%', 'color': AppColors.danger},
        ]),
        const SizedBox(height: 12),
        _infoCard('Resumo Geral', [
          {'label': 'Ticket médio', 'valor': 'R\$ 68,50'},
          {'label': 'Retenção de clientes', 'valor': '74%'},
          {'label': 'NPS', 'valor': '87'},
          {'label': 'Crescimento mensal', 'valor': '+12%'},
        ]),
      ],
    );
  }

  Widget _chartCard(String title, List<_BarData> bars) {
    final maxVal = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.dark)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: bars.map((b) {
                final h = (b.value / maxVal) * 90;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${b.value}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.grey)),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: h,
                      decoration: BoxDecoration(
                        color: b.color,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(b.label,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.grey)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieCard(String title, List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.dark)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: item['color'] as Color,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['label'],
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.dark)),
                              Text(item['valor'],
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          LinearProgressIndicator(
                            value: double.parse(
                                    (item['valor'] as String).replaceAll('%', '')) /
                                100,
                            backgroundColor: AppColors.greyLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                item['color'] as Color),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.dark)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['label']!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grey)),
                    Text(item['valor']!,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final double value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}
