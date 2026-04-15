import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/mypet_app_bar.dart';

class EstabAvaliacoesScreen extends StatefulWidget {
  const EstabAvaliacoesScreen({super.key});
  @override
  State<EstabAvaliacoesScreen> createState() => _EstabAvaliacoesScreenState();
}

class _EstabAvaliacoesScreenState extends State<EstabAvaliacoesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _avaliacoes = [
    {'nome': 'João Santos', 'nota': 5, 'comentario': 'Excelente atendimento! Meu pet ficou ótimo, com certeza voltarei.', 'data': '2026-02-15'},
    {'nome': 'Ana Alves', 'nota': 4, 'comentario': 'Bom atendimento, mas poderia melhorar o espaço de espera.', 'data': '2026-02-20'},
    {'nome': 'Pedro Almeida', 'nota': 5, 'comentario': 'Melhor pet shop da região! Atendimento incrível.', 'data': '2026-02-28'},
    {'nome': 'Fernanda Souza', 'nota': 4, 'comentario': 'Serviço bem feito, pessoal educado. Recomendo!', 'data': '2026-03-02'},
  ];

  final _reclamacoes = [
    {'nome': 'Carlos M.', 'assunto': 'Atraso no atendimento', 'descricao': 'Esperamos mais de 1 hora além do horário marcado.', 'data': '2026-02-10', 'status': 'RESPONDIDA'},
    {'nome': 'Paula T.', 'assunto': 'Serviço incompleto', 'descricao': 'A tosa não ficou como combinado.', 'data': '2026-03-01', 'status': 'PENDENTE'},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('2', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Pendentes', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    const Text('2', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Confirmados', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    const Text('4.8', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Avaliação', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
              tabs: const [Tab(text: 'Avaliações'), Tab(text: 'Reclamações')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('4.6',
                              style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark)),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < 4 ? Icons.star : Icons.star_half,
                                    color: const Color(0xFFFFC107),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${_avaliacoes.length} avaliações',
                                  style: const TextStyle(
                                      color: AppColors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._avaliacoes.map((av) => _AvalCard(av: av)),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: _reclamacoes.map((r) => _ReclamCard(r: r)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvalCard extends StatelessWidget {
  final Map<String, dynamic> av;
  const _AvalCard({required this.av});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(av['nome'][0],
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(av['nome'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(av['data'],
                        style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < av['nota'] ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFC107),
                          size: 14,
                        )),
              ),
            ],
          ),
          if (av['comentario'] != null && av['comentario'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(av['comentario'],
                style: const TextStyle(fontSize: 13, color: AppColors.grey)),
          ],
        ],
      ),
    );
  }
}

class _ReclamCard extends StatelessWidget {
  final Map<String, dynamic> r;
  const _ReclamCard({required this.r});

  @override
  Widget build(BuildContext context) {
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
                child: Text(r['assunto'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.dark)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPendente
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(r['status'],
                    style: TextStyle(
                        color: isPendente ? AppColors.warning : AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(r['nome'],
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 6),
          Text(r['descricao'],
              style: const TextStyle(fontSize: 13, color: AppColors.dark)),
          if (isPendente) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Responder',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
