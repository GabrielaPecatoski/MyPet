import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/availability.dart';
import '../models/establishment.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
<<<<<<< HEAD
=======
import '../services/availability_service.dart';
import '../services/establishment_service.dart';
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD

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
=======
  List<ServiceModel> _services = [];
  ScheduleModel? _schedule;
  bool _servicesLoaded = false;

>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final e = ModalRoute.of(context)!.settings.arguments as EstablishmentModel;
<<<<<<< HEAD
    _loadReviews(e.id);
=======
    if (!_servicesLoaded) {
      _servicesLoaded = true;
      _loadServices(e.id);
      _loadReviews(e.id);
      _loadSchedule(e.id);
    }
  }

  Future<void> _loadServices(String establishmentId) async {
    try {
      final services = await EstablishmentService.fetchServices(establishmentId);
      if (mounted) setState(() => _services = services);
    } catch (_) {}
  }

  Future<void> _loadSchedule(String establishmentId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final schedule = await AvailabilityService.getSchedule(
        token: token,
        estabId: establishmentId,
      );
      if (mounted) setState(() => _schedule = schedule);
    } catch (_) {}
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
      if (mounted) setState(() => _reviews = _mockReviews);
=======
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

<<<<<<< HEAD
=======
  double get _liveRating {
    if (_reviews.isEmpty) return 0.0;
    return _reviews.fold<int>(0, (s, r) => s + r.rating) / _reviews.length;
  }

  int get _liveReviewCount => _reviews.length;

  String _fmtTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return m == 0 ? '${h}h' : '${h}h${parts[1]}';
  }

  String _formatScheduleHours(ScheduleModel schedule) {
    final byDay = {for (final d in schedule.days) d.dayOfWeek: d};
    final parts = <String>[];

    final mon = byDay[1];
    final fri = byDay[5];
    if (mon != null && mon.isOpen) {
      final sameAsFri = fri != null &&
          fri.isOpen &&
          fri.startTime == mon.startTime &&
          fri.endTime == mon.endTime;
      final label = sameAsFri ? 'Seg–Sex' : 'Seg';
      parts.add('$label: ${_fmtTime(mon.startTime)}–${_fmtTime(mon.endTime)}');
    }

    final sat = byDay[6];
    if (sat != null && sat.isOpen) {
      parts.add('Sáb: ${_fmtTime(sat.startTime)}–${_fmtTime(sat.endTime)}');
    }

    return parts.isEmpty ? 'Fechado' : parts.join('  •  ');
  }

>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
                      Text(e.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFC107), size: 18),
                          const SizedBox(width: 4),
<<<<<<< HEAD
                          Text('${e.rating}',
=======
                          Text(_liveRating > 0 ? _liveRating.toStringAsFixed(1) : '–',
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.dark)),
                          Flexible(
<<<<<<< HEAD
                            child: Text(' (${e.reviewCount} avaliações)',
=======
                            child: Text(' ($_liveReviewCount avaliações)',
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
                      _infoRow(Icons.location_on_outlined, e.address),
                      const SizedBox(height: 8),
                      _infoRow(Icons.phone_outlined, e.phone),
                      const SizedBox(height: 8),
                      _infoRow(Icons.access_time_outlined,
<<<<<<< HEAD
                          'Seg–Sex: 8h–18h  •  Sáb: 8h–13h'),
=======
                          _schedule != null ? _formatScheduleHours(_schedule!) : '...'),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                    ],
                  ),
                ),
              ),

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

<<<<<<< HEAD
              if (e.services.isEmpty)
=======
              if (_services.isEmpty)
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
                    final service = e.services[i];
=======
                    final service = _services[i];
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
                  childCount: e.services.length,
=======
                  childCount: _services.length,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                ),
              ),

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
<<<<<<< HEAD
                      if (e.rating > 0)
=======
                      if (_liveRating > 0)
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
                                e.rating.toStringAsFixed(1),
=======
                                _liveRating.toStringAsFixed(1),
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(height: 6),
<<<<<<< HEAD
                              _StarRow(rating: e.rating),
                              const SizedBox(height: 4),
                              Text(
                                '${e.reviewCount} avaliações',
=======
                              _StarRow(rating: _liveRating),
                              const SizedBox(height: 4),
                              Text(
                                '$_liveReviewCount avaliações',
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

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
