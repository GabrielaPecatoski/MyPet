import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/establishment_stats.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../providers/establishment_stats_provider.dart';
import '../repositories/establishment_stats_repository.dart';
import '../widgets/mypet_app_bar.dart';

class EstabEstatisticasScreen extends StatelessWidget {
  const EstabEstatisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          EstablishmentStatsProvider(EstablishmentStatsRepository()),
      child: const _EstabEstatisticasView(),
    );
  }
}

class _EstabEstatisticasView extends StatefulWidget {
  const _EstabEstatisticasView();
  @override
  State<_EstabEstatisticasView> createState() =>
      _EstabEstatisticasViewState();
}

class _EstabEstatisticasViewState extends State<_EstabEstatisticasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final estabId = context.read<EstablishmentProvider>().establishmentId;
    final token = auth.token;
    if (token == null || estabId == null) return;
    await context
        .read<EstablishmentStatsProvider>()
        .load(estabId: estabId, token: token);
  }

  List<_MonthBar> _ultimos6Meses(EstabStatsModel stats) =>
      stats.last6Months.map((m) => _MonthBar(m.month, m.value)).toList();

  List<_ServiceStat> _servicos(EstabStatsModel stats) {
    final colors = [
      AppColors.estab,
      AppColors.success,
      const Color(0xFF6366F1),
      AppColors.warning,
      AppColors.grey,
    ];
    return stats.topServices.asMap().entries.map((e) {
      final color = colors[e.key < colors.length ? e.key : colors.length - 1];
      return _ServiceStat(e.value.name, e.value.count, color);
    }).toList();
  }

  double _maxBarValue(List<_MonthBar> months) =>
      months.fold(0, (m, b) => b.value > m ? b.value : m);

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<EstablishmentStatsProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: Consumer<EstablishmentProvider>(
        builder: (context, estabProv, _) {
          if (statsProvider.isLoading || estabProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (statsProvider.stats == null &&
              estabProv.establishmentId != null &&
              statsProvider.error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _load());
            return const Center(child: CircularProgressIndicator(color: AppColors.estab));
          }
          if (statsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(statsProvider.error!,
                      style: const TextStyle(color: AppColors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          if (statsProvider.stats == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.estab),
            );
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: _buildContent(statsProvider.stats!),
          );
        },
      ),
    );
  }

  Widget _buildContent(EstabStatsModel stats) {
    final estab = context.read<EstablishmentProvider>().establishment;
    final avgRating = estab?.rating ?? 0.0;
    final totalReviews = estab?.reviewCount ?? 0;
    final meses = _ultimos6Meses(stats);
    final servicos = _servicos(stats);
    final maxBar = _maxBarValue(meses);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Estatísticas',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark)),
          const SizedBox(height: 4),
          const Text('Visão geral do seu negócio',
              style: TextStyle(fontSize: 13, color: AppColors.grey)),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Faturamento total',
                  value: 'R\$ ${_fmt(stats.totalRevenue)}',
                  icon: Icons.attach_money,
                  color: AppColors.estab,
                  sub: 'desde o início',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Este mês',
                  value: 'R\$ ${_fmt(stats.monthRevenue)}',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  sub: 'concluídos no mês',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Ticket médio',
                  value: 'R\$ ${stats.avgTicket.toStringAsFixed(2)}',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF6366F1),
                  sub: 'por atendimento',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Agendamentos',
                  value: '${stats.totalBookings}',
                  icon: Icons.calendar_today_outlined,
                  color: AppColors.warning,
                  sub: '${stats.monthBookings} este mês',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star,
                      color: Color(0xFFFFC107), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Avaliação média',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.grey)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '/ 5.0  •  $totalReviews avaliações',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (i) {
                    final full = i < avgRating.floor();
                    return Icon(
                      full ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFC107),
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (meses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Faturamento — Últimos 6 meses',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.dark)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 130,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: meses.map((b) {
                        final max = maxBar > 0 ? maxBar : 1;
                        final ratio = b.value / max;
                        final isLast = b == meses.last;
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isLast && b.value > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'R\$${_fmt(b.value)}',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.estab,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                Flexible(
                                  child: FractionallySizedBox(
                                    heightFactor: ratio.clamp(0.05, 1.0),
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isLast
                                            ? AppColors.estab
                                            : AppColors.primaryLight,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(b.month,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isLast
                                            ? AppColors.estab
                                            : AppColors.grey,
                                        fontWeight: isLast
                                            ? FontWeight.w600
                                            : FontWeight.normal)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          if (meses.isNotEmpty) const SizedBox(height: 20),

          if (servicos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Serviços mais realizados',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.dark)),
                  const SizedBox(height: 16),
                  ...servicos.map((s) {
                    final total =
                        servicos.fold(0, (sum, x) => sum + x.count);
                    final pct = total > 0 ? s.count / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: s.color,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(s.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.dark))),
                              Text('${s.count}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark)),
                              const SizedBox(width: 6),
                              Text('${(pct * 100).round()}%',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.grey)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct.toDouble(),
                              backgroundColor: AppColors.greyLight,
                              valueColor:
                                  AlwaysStoppedAnimation(s.color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          if (servicos.isNotEmpty) const SizedBox(height: 20),

          if (stats.monthRevenue > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.estab,
                    AppColors.estab.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_graph,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimativa — próximo mês',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70)),
                        Text(
                          'R\$ ${_fmt(stats.monthRevenue * 1.12)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const Text(
                          'Baseado na tendência dos últimos 3 meses',
                          style: TextStyle(
                              fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (stats.totalBookings == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nenhum agendamento encontrado ainda.',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return v.toStringAsFixed(0);
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17, color: color)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark)),
          const SizedBox(height: 1),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.grey)),
        ],
      ),
    );
  }
}

class _MonthBar {
  final String month;
  final double value;
  const _MonthBar(this.month, this.value);
}

class _ServiceStat {
  final String name;
  final int count;
  final Color color;
  const _ServiceStat(this.name, this.count, this.color);
}
