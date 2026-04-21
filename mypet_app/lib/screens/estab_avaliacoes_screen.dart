import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/booking_provider.dart';
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
    {
      'nome': 'João Santos',
      'nota': 5,
      'comentario': 'Excelente atendimento! Meu pet ficou ótimo, com certeza voltarei.',
      'data': '15/02/2026',
    },
    {
      'nome': 'Ana Alves',
      'nota': 4,
      'comentario': 'Bom atendimento, mas poderia melhorar o espaço de espera.',
      'data': '20/02/2026',
    },
    {
      'nome': 'Pedro Almeida',
      'nota': 5,
      'comentario': 'Melhor pet shop da região! Atendimento incrível.',
      'data': '28/02/2026',
    },
    {
      'nome': 'Fernanda Souza',
      'nota': 4,
      'comentario': 'Serviço bem feito, pessoal educado. Recomendo!',
      'data': '02/03/2026',
    },
  ];

  final _reclamacoes = [
    {
      'nome': 'Carlos M.',
      'assunto': 'Atraso no atendimento',
      'descricao': 'Esperamos mais de 1 hora além do horário marcado.',
      'data': '10/02/2026',
      'status': 'RESPONDIDA',
    },
    {
      'nome': 'Paula T.',
      'assunto': 'Serviço incompleto',
      'descricao': 'A tosa não ficou como combinado.',
      'data': '01/03/2026',
      'status': 'PENDENTE',
    },
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

  double get _mediaNota {
    if (_avaliacoes.isEmpty) return 0;
    final total = _avaliacoes.fold<int>(0, (sum, a) => sum + (a['nota'] as int));
    return total / _avaliacoes.length;
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header roxo
            EstabPurpleHeader(
              pendentes: booking.pendentes.length,
              confirmados: booking.confirmados.length,
              avaliacao: _mediaNota.toStringAsFixed(1),
            ),

            // Tabs
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
                  Tab(text: 'Avaliações'),
                  Tab(text: 'Reclamações'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // ── Avaliações ──────────────────────────────────
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Score geral
                      Container(
                        padding: const EdgeInsets.all(16),
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
                            Text(
                              _mediaNota.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < _mediaNota.floor()
                                          ? Icons.star
                                          : (i < _mediaNota
                                              ? Icons.star_half
                                              : Icons.star_border),
                                      color: const Color(0xFFFFC107),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_avaliacoes.length} avaliações',
                                  style: const TextStyle(
                                      color: AppColors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._avaliacoes
                          .map((av) => _AvalCard(av: av))
                          ,
                    ],
                  ),

                  // ── Reclamações ─────────────────────────────────
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        _reclamacoes.map((r) => _ReclamCard(r: r)).toList(),
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

class _AvalCard extends StatelessWidget {
  final Map<String, dynamic> av;
  const _AvalCard({required this.av});

  @override
  Widget build(BuildContext context) {
    final nota = av['nota'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  (av['nome'] as String)[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(av['nome'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.dark)),
                    Text(av['data'] as String,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < nota ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          if ((av['comentario'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              av['comentario'] as String,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.grey, height: 1.4),
            ),
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
                child: Text(r['assunto'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.dark)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPendente
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r['status'] as String,
                  style: TextStyle(
                      color: isPendente ? AppColors.warning : AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(r['nome'] as String,
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 6),
          Text(r['descricao'] as String,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.dark, height: 1.4)),
          if (isPendente) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
                child: const Text('Responder',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
