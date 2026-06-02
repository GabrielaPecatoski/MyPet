import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
<<<<<<< HEAD
import '../providers/booking_provider.dart';
=======
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
import '../widgets/mypet_app_bar.dart';

class EstabAvaliacoesScreen extends StatefulWidget {
  const EstabAvaliacoesScreen({super.key});
  @override
  State<EstabAvaliacoesScreen> createState() => _EstabAvaliacoesScreenState();
}

class _EstabAvaliacoesScreenState extends State<EstabAvaliacoesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

<<<<<<< HEAD
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
=======
  List<Map<String, dynamic>> _avaliacoes = [];
  List<Map<String, dynamic>> _reclamacoes = [];
  bool _loading = true;
  String? _token;
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _token = auth.token;
    _loadData(auth.user?.id);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  double get _mediaNota {
    if (_avaliacoes.isEmpty) return 0;
    final total = _avaliacoes.fold<int>(0, (sum, a) => sum + (a['nota'] as int));
=======
  Future<void> _loadData(String? userId) async {
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final estabData = await ApiService.get('/establishments/owner/$userId', token: _token);
      final estabs = estabData is List ? estabData : [estabData];
      if (estabs.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final id = (estabs.first as Map<String, dynamic>)['id'] as String? ?? '';
      await Future.wait([_loadAvaliacoes(id), _loadReclamacoes(id)]);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadAvaliacoes(String estabId) async {
    try {
      final data = await ApiService.get('/reviews/establishment/$estabId');
      setState(() => _avaliacoes = (data as List).cast<Map<String, dynamic>>());
    } catch (_) {
      setState(() => _avaliacoes = []);
    }
  }

  Future<void> _loadReclamacoes(String estabId) async {
    try {
      final data = await ApiService.get('/reviews/complaints/establishment/$estabId', token: _token);
      setState(() => _reclamacoes = (data as List).cast<Map<String, dynamic>>());
    } catch (_) {
      setState(() => _reclamacoes = []);
    }
  }

  double get _mediaNota {
    if (_avaliacoes.isEmpty) return 0;
    final total = _avaliacoes.fold<num>(0, (sum, a) => sum + ((a['rating'] as num?) ?? 0));
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
            EstabPurpleHeader(
              pendentes: booking.pendentes.length,
              confirmados: booking.confirmados.length,
              avaliacao: _mediaNota.toStringAsFixed(1),
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
                  Tab(text: 'Avaliações'),
                  Tab(text: 'Reclamações'),
                ],
              ),
            ),

            Expanded(
<<<<<<< HEAD
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

                  ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        _reclamacoes.map((r) => _ReclamCard(r: r)).toList(),
                  ),
                ],
              ),
=======
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : TabBarView(
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
                            if (_avaliacoes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text('Nenhuma avaliação ainda',
                                      style: TextStyle(color: AppColors.grey)),
                                ),
                              )
                            else
                              ..._avaliacoes.map((av) => _AvalCard(av: av)),
                          ],
                        ),

                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: _reclamacoes.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(
                                      child: Text('Nenhuma reclamação',
                                          style: TextStyle(color: AppColors.grey)),
                                    ),
                                  )
                                ]
                              : _reclamacoes.map((r) => _ReclamCard(r: r)).toList(),
                        ),
                      ],
                    ),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
    final nota = av['nota'] as int;
=======
    final nota = ((av['rating'] as num?) ?? 0).toInt();
    final nome = av['userName'] as String? ?? 'Usuário';
    final comentario = av['comment'] as String? ?? '';
    final rawDate = av['createdAt'];
    final data = rawDate != null ? _formatDate(rawDate.toString()) : '';

>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
                  (av['nome'] as String)[0].toUpperCase(),
=======
                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
<<<<<<< HEAD
                    Text(av['nome'] as String,
=======
                    Text(nome,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.dark)),
<<<<<<< HEAD
                    Text(av['data'] as String,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.grey)),
=======
                    if (data.isNotEmpty)
                      Text(data,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.grey)),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
          if ((av['comentario'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              av['comentario'] as String,
=======
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comentario,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
              style: const TextStyle(
                  fontSize: 13, color: AppColors.grey, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _ReclamCard extends StatelessWidget {
  final Map<String, dynamic> r;
  const _ReclamCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final isPendente = r['status'] == 'PENDENTE';
    final assunto = r['subject'] as String? ?? '';
    final nome = r['userName'] as String? ?? 'Usuário';
    final descricao = r['description'] as String? ?? '';
    final status = r['status'] as String? ?? 'PENDENTE';

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
<<<<<<< HEAD
                child: Text(r['assunto'] as String,
=======
                child: Text(assunto,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
                  r['status'] as String,
=======
                  status,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                  style: TextStyle(
                      color: isPendente ? AppColors.warning : AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
<<<<<<< HEAD
          Text(r['nome'] as String,
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 6),
          Text(r['descricao'] as String,
=======
          Text(nome,
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 6),
          Text(descricao,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
