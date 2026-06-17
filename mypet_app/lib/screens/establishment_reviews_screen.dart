import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/complaint.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/establishment_reviews_provider.dart';
import '../repositories/establishment_reviews_repository.dart';
import '../widgets/mypet_app_bar.dart';

class EstabAvaliacoesScreen extends StatelessWidget {
  const EstabAvaliacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return ChangeNotifierProvider(
      create: (_) =>
          EstablishmentReviewsProvider(EstablishmentReviewsRepository())
            ..load(auth.user?.id, token: auth.token),
      child: const _EstabAvaliacoesView(),
    );
  }
}

class _EstabAvaliacoesView extends StatefulWidget {
  const _EstabAvaliacoesView();
  @override
  State<_EstabAvaliacoesView> createState() => _EstabAvaliacoesViewState();
}

class _EstabAvaliacoesViewState extends State<_EstabAvaliacoesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

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
    final booking = context.watch<BookingProvider>();
    final provider = context.watch<EstablishmentReviewsProvider>();
    final avaliacoes = provider.reviews;
    final reclamacoes = provider.complaints;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            EstabPurpleHeader(
              pendentes: booking.pendentes.length,
              confirmados: booking.confirmados.length,
              avaliacao: provider.mediaNota.toStringAsFixed(1),
            ),

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: AppColors.estab,
                indicatorWeight: 3,
                labelColor: AppColors.estab,
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
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.estab))
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
                                    provider.mediaNota.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.estab),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < provider.mediaNota.floor()
                                                ? Icons.star
                                                : (i < provider.mediaNota
                                                    ? Icons.star_half
                                                    : Icons.star_border),
                                            color: const Color(0xFFFFC107),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${avaliacoes.length} avaliações',
                                        style: const TextStyle(
                                            color: AppColors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (avaliacoes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text('Nenhuma avaliação ainda',
                                      style: TextStyle(color: AppColors.grey)),
                                ),
                              )
                            else
                              ...avaliacoes.map((av) => _AvalCard(av: av)),
                          ],
                        ),

                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: reclamacoes.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(
                                      child: Text('Nenhuma reclamação',
                                          style: TextStyle(color: AppColors.grey)),
                                    ),
                                  )
                                ]
                              : reclamacoes.map((r) => _ReclamCard(r: r)).toList(),
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
  final ReviewModel av;
  const _AvalCard({required this.av});

  @override
  Widget build(BuildContext context) {
    final nota = av.rating;
    final nome = av.userName;
    final comentario = av.comment ?? '';
    final data = _formatDate(av.createdAt);

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
                  nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.estab, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.dark)),
                    if (data.isNotEmpty)
                      Text(data,
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
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comentario,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.grey, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _ReclamCard extends StatelessWidget {
  final ComplaintModel r;
  const _ReclamCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final isPendente = r.isPendente;
    final assunto = r.subject;
    final nome = r.userName;
    final descricao = r.description;
    final status = r.status;

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
                child: Text(assunto,
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
                  status,
                  style: TextStyle(
                      color: isPendente ? AppColors.warning : AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(nome,
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 6),
          Text(descricao,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.dark, height: 1.4)),
          if (isPendente) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.estab,
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
