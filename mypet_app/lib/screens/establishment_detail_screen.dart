import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/availability.dart';
import '../models/establishment.dart';
import '../models/review.dart';
import '../models/veterinarian.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_detail_provider.dart';
import '../repositories/establishment_detail_repository.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';
import 'schedule_screen.dart' show ScheduleArgs;

class EstablishmentDetailScreen extends StatelessWidget {
  const EstablishmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          EstablishmentDetailProvider(EstablishmentDetailRepository()),
      child: const _EstablishmentDetailView(),
    );
  }
}

class _EstablishmentDetailView extends StatefulWidget {
  const _EstablishmentDetailView();

  @override
  State<_EstablishmentDetailView> createState() =>
      _EstablishmentDetailViewState();
}

class _EstablishmentDetailViewState
    extends State<_EstablishmentDetailView> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final e = ModalRoute.of(context)!.settings.arguments as EstablishmentModel;
    if (!_loaded) {
      _loaded = true;
      final token = context.read<AuthProvider>().token;
      context.read<EstablishmentDetailProvider>().load(e.id, token: token);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final establishment =
        ModalRoute.of(context)!.settings.arguments as EstablishmentModel;
    final e = establishment;
    final provider = context.watch<EstablishmentDetailProvider>();
    final services = provider.services;
    final reviews = provider.reviews;
    final schedule = provider.schedule;
    final liveRating = provider.liveRating;
    final liveReviewCount = provider.liveReviewCount;
    final vets = provider.vets;

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
                      e.isPetShop && !e.isVeterinario ? Icons.pets : Icons.local_hospital,
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
                          Text(liveRating > 0 ? liveRating.toStringAsFixed(1) : '–',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.dark)),
                          Flexible(
                            child: Text(' ($liveReviewCount avaliações)',
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
                          schedule != null ? _formatScheduleHours(schedule) : '...'),

                      if (e.isVeterinario) ...[
                        const SizedBox(height: 14),
                        _vetInfoSection(e),
                      ],
                    ],
                  ),
                ),
              ),

              if (e.isVeterinario && e.atendeEmergencia)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _EmergencyBanner(establishment: e),
                  ),
                ),

              if (vets.isNotEmpty)
                SliverToBoxAdapter(child: _vetsSection(e, vets)),

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

              if (services.isEmpty)
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
                    final service = services[i];
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(service.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.dark)),
                                      ),
                                      if (service.isVeterinary)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text('VET',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF2E7D32),
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
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
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(service.categoriaLabel,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              service.priceLabel,
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
                  childCount: services.length,
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
                      if (liveRating > 0)
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
                                liveRating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                              const SizedBox(height: 6),
                              _StarRow(rating: liveRating),
                              const SizedBox(height: 4),
                              Text(
                                '$liveReviewCount avaliações',
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

              if (provider.reviewsLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  ),
                )
              else if (reviews.isEmpty)
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
                      child: _ReviewCard(review: reviews[i]),
                    ),
                    childCount: reviews.length,
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

  Widget _vetsSection(EstablishmentModel e, List<VeterinarianModel> vets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Veterinários',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 8),
          ...vets.map((v) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medical_services_outlined,
                              color: AppColors.estab, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.dark)),
                              Text('${v.especialidade ?? 'Clínico geral'} · CRMV: ${v.crmv}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                              const SizedBox(height: 4),
                              Row(children: [
                                if (v.atende24h)
                                  _vetBadge('24h', AppColors.danger),
                                if (v.atendeDomicilio)
                                  _vetBadge('Domicílio', AppColors.estab),
                                if (v.disponivel)
                                  _vetBadge('Disponível', AppColors.success),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/schedule',
                          arguments: ScheduleArgs(
                            establishment: e,
                            vetId: v.id,
                            vetName: v.name,
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: const Text('Agendar consulta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.estab,
                          side: const BorderSide(color: AppColors.estab),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _vetBadge(String text, Color color) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _vetInfoSection(EstablishmentModel e) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_hospital, color: Color(0xFF2E7D32), size: 18),
              SizedBox(width: 6),
              Text('Atendimento Veterinário',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 10),
          if (e.crmv != null && e.crmv!.isNotEmpty)
            _vetInfoRow(Icons.badge_outlined, 'CRMV: ${e.crmv}'),
          if (e.atendimento24h)
            _vetInfoRow(Icons.access_time_filled, 'Atendimento 24 horas'),
          if (e.atendeEmergencia)
            _vetInfoRow(Icons.warning_amber_rounded, 'Atende emergências',
                color: AppColors.danger),
        ],
      ),
    );
  }

  Widget _vetInfoRow(IconData icon, String text, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color ?? const Color(0xFF388E3C)),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                    fontSize: 13, color: color ?? const Color(0xFF388E3C))),
          ],
        ),
      );

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

class _EmergencyBanner extends StatelessWidget {
  final EstablishmentModel establishment;
  const _EmergencyBanner({required this.establishment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEmergencyDialog(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergência Veterinária',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text('Este estabelecimento atende emergências. Toque para ligar.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.emergency,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Emergência Veterinária',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(establishment.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.dark)),
            const SizedBox(height: 4),
            Text(establishment.address,
                style:
                    const TextStyle(color: AppColors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            if (establishment.phone.isNotEmpty)
              Text('Telefone: ${establishment.phone}',
                  style: const TextStyle(
                      color: AppColors.dark, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar',
                style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, elevation: 0),
            child: const Text('Entendido',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
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
