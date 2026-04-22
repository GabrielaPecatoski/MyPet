import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/establishment.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../services/review_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';

class EstablishmentDetailScreen extends StatefulWidget {
  const EstablishmentDetailScreen({super.key});

  @override
  State<EstablishmentDetailScreen> createState() =>
      _EstablishmentDetailScreenState();
}

class _EstablishmentDetailScreenState
    extends State<EstablishmentDetailScreen> {
  List<ReviewModel> _reviews = [];
  bool _reviewsLoading = true;

  static final List<ReviewModel> _mockReviews = [
    ReviewModel(
      id: '1',
      userId: 'u1',
      userName: 'João Santos',
      establishmentId: '',
      bookingId: '',
      rating: 5,
      comment: 'Excelente atendimento! Meu cachorro ficou muito bem cuidado.',
      createdAt: DateTime(2026, 3, 12),
    ),
    ReviewModel(
      id: '2',
      userId: 'u2',
      userName: 'Ana Costa',
      establishmentId: '',
      bookingId: '',
      rating: 4,
      comment: 'Bom serviço, mas o preço poderia ser melhor.',
      createdAt: DateTime(2026, 3, 10),
    ),
    ReviewModel(
      id: '3',
      userId: 'u3',
      userName: 'Pedro Almeida',
      establishmentId: '',
      bookingId: '',
      rating: 4,
      comment: 'Melhor pet shop da região! Sempre volto com meus pets.',
      createdAt: DateTime(2026, 3, 10),
    ),
    ReviewModel(
      id: '4',
      userId: 'u4',
      userName: 'Fernanda Souza',
      establishmentId: '',
      bookingId: '',
      rating: 4,
      comment: 'Atendimento excelente, apenas o tempo de espera poderia ser menor.',
      createdAt: DateTime(2026, 3, 10),
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final e = ModalRoute.of(context)!.settings.arguments as EstablishmentModel;
    _loadReviews(e.id);
  }

  Future<void> _loadReviews(String establishmentId) async {
    final auth = context.read<AuthProvider>();
    try {
      final reviews = await ReviewService.getByEstablishment(
        establishmentId,
        token: auth.token,
      );
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {
      if (mounted) setState(() => _reviews = _mockReviews);
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final establishment =
        ModalRoute.of(context)!.settings.arguments as EstablishmentModel;
    final e = establishment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        items: clientNavItems,
        onTap: (i) => Navigator.pushNamedAndRemoveUntil(
            context, '/home', (r) => false,
            arguments: i),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Banner
              SliverToBoxAdapter(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: AppColors.primary,
                  child: Center(
                    child: Icon(
                      e.type == 'PET_SHOP' ? Icons.pets : Icons.local_hospital,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome
                      Text(e.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark)),
                      const SizedBox(height: 6),
                      // Rating + tipo
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFC107), size: 18),
                          const SizedBox(width: 4),
                          Text('${e.rating}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.dark)),
                          Flexible(
                            child: Text(' (${e.reviewCount} avaliações)',
                                style: const TextStyle(
                                    color: AppColors.grey, fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(e.typeLabel,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Endereço
                      _infoRow(Icons.location_on_outlined, e.address),
                      const SizedBox(height: 8),
                      // Telefone
                      _infoRow(Icons.phone_outlined, e.phone),
                      const SizedBox(height: 8),
                      // Horário
                      _infoRow(Icons.access_time_outlined,
                          'Seg–Sex: 8h–18h  •  Sáb: 8h–13h'),
                    ],
                  ),
                ),
              ),

              // Seção Serviços
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: const Text(
                    'Serviços Oferecidos',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark),
                  ),
                ),
              ),

              if (e.services.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: const Text('Nenhum serviço cadastrado.',
                          style: TextStyle(color: AppColors.grey)),
                    ),
                  ),
                ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final service = e.services[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Container(
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.dark)),
                                  if (service.description != null &&
                                      service.description!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(service.description!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.grey)),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 13, color: AppColors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${service.durationMinutes} min',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'R\$ ${service.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: e.services.length,
                ),
              ),

              // Seção Avaliações
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avaliações',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark),
                      ),
                      const SizedBox(height: 12),
                      // Card de média
                      if (e.rating > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                e.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(height: 6),
                              _StarRow(rating: e.rating),
                              const SizedBox(height: 4),
                              Text(
                                '${e.reviewCount} avaliações',
                                style: const TextStyle(
                                    color: AppColors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Lista de reviews
              if (_reviewsLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  ),
                )
              else if (_reviews.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Nenhuma avaliação ainda.',
                        style: TextStyle(color: AppColors.grey, fontSize: 13)),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _ReviewCard(review: _reviews[i]),
                    ),
                    childCount: _reviews.length,
                  ),
                ),

              // Espaço para o botão fixo
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // Botão fixo no rodapé
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/schedule',
                    arguments: establishment,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Agendar Serviço',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: AppColors.grey)),
          ),
        ],
      );
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && (i < rating);
        return Icon(
          filled
              ? Icons.star
              : half
                  ? Icons.star_half
                  : Icons.star_border,
          color: const Color(0xFFFFC107),
          size: 22,
        );
      }),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final initials = review.userName.isNotEmpty
        ? review.userName.trim().split(' ').map((w) => w[0]).take(1).join()
        : '?';
    final dateStr =
        '${review.createdAt.year}-${review.createdAt.month.toString().padLeft(2, '0')}-${review.createdAt.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.dark)),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < review.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFFFFC107),
                                size: 14,
                              )),
                    ),
                  ],
                ),
              ),
              Text(dateStr,
                  style: const TextStyle(fontSize: 11, color: AppColors.grey)),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!,
                style: const TextStyle(fontSize: 13, color: AppColors.grey)),
          ],
        ],
      ),
    );
  }
}
