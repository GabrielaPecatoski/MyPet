import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/review_service.dart';
import '../widgets/mypet_app_bar.dart';

class EstabAvaliacoesScreen extends StatefulWidget {
  const EstabAvaliacoesScreen({super.key});
  @override
  State<EstabAvaliacoesScreen> createState() => _EstabAvaliacoesScreenState();
}

class _EstabAvaliacoesScreenState extends State<EstabAvaliacoesScreen> {
  List<ReviewModel> _reviews = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    final estabId = context.read<EstablishmentProvider>().establishmentId;
    final token = context.read<AuthProvider>().token;
    if (estabId == null) return;
    setState(() => _loading = true);
    try {
      final reviews = await ReviewService.getByEstablishment(estabId, token: token);
      setState(() => _reviews = reviews);
    } catch (_) {
      setState(() => _reviews = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  double get _mediaNota {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold<double>(0, (s, r) => s + r.rating) / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          EstabPurpleHeader(
            pendentes: booking.pendentes.length,
            confirmados: booking.confirmados.length,
            avaliacao: _mediaNota.toStringAsFixed(1),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _loadReviews,
                    color: AppColors.primary,
                    child: _reviews.isEmpty
                        ? ListView(children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Column(children: [
                                Icon(Icons.star_border, size: 48, color: AppColors.greyLight),
                                SizedBox(height: 12),
                                Text('Nenhuma avaliação ainda.',
                                    style: TextStyle(color: AppColors.grey, fontSize: 14)),
                              ]),
                            ),
                          ])
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Row(children: [
                                  Text(
                                    _mediaNota.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(
                                      children: List.generate(5, (i) => Icon(
                                        i < _mediaNota.floor()
                                            ? Icons.star
                                            : (i < _mediaNota ? Icons.star_half : Icons.star_border),
                                        color: const Color(0xFFFFC107), size: 22,
                                      )),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${_reviews.length} avaliações',
                                        style: const TextStyle(color: AppColors.grey, fontSize: 13)),
                                  ]),
                                ]),
                              ),
                              const SizedBox(height: 12),
                              ..._reviews.map((r) => _AvalCard(review: r)),
                            ],
                          ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _AvalCard extends StatelessWidget {
  final ReviewModel review;
  const _AvalCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final initials = review.userName.isNotEmpty
        ? review.userName.trim().split(' ').map((w) => w[0]).take(1).join().toUpperCase()
        : '?';
    final dateStr =
        '${review.createdAt.day.toString().padLeft(2, '0')}/${review.createdAt.month.toString().padLeft(2, '0')}/${review.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Text(initials,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.dark)),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
            ]),
          ),
          Row(
            children: List.generate(5, (i) => Icon(
              i < review.rating ? Icons.star : Icons.star_border,
              color: const Color(0xFFFFC107), size: 15,
            )),
          ),
        ]),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.comment!,
              style: const TextStyle(fontSize: 13, color: AppColors.grey, height: 1.4)),
        ],
      ]),
    );
  }
}
