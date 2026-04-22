import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/mypet_app_bar.dart';

class EstabEstatisticasScreen extends StatefulWidget {
  const EstabEstatisticasScreen({super.key});
  @override
  State<EstabEstatisticasScreen> createState() =>
      _EstabEstatisticasScreenState();
}

class _EstabEstatisticasScreenState extends State<EstabEstatisticasScreen> {
  // Mock data — substituir por chamada real à API
  final double _totalReceita = 8_450.00;
  final double _receitaMes = 2_130.00;
  final double _ticketMedio = 87.50;
  final int _agendamentosTotal = 96;
  final int _agendamentosMes = 24;
  final double _avaliacaoMedia = 4.7;
  final int _totalAvaliacoes = 38;

  final List<_MonthBar> _ultimos6Meses = [
    _MonthBar('Nov', 980),
    _MonthBar('Dez', 1240),
    _MonthBar('Jan', 870),
    _MonthBar('Fev', 1560),
    _MonthBar('Mar', 1800),
    _MonthBar('Abr', 2130),
  ];

  final List<_ServiceStat> _servicos = [
    _ServiceStat('Banho e Tosa', 42, AppColors.primary),
    _ServiceStat('Consulta Vet.', 18, AppColors.success),
    _ServiceStat('Hospedagem', 14, const Color(0xFF6366F1)),
    _ServiceStat('Adestramento', 12, AppColors.warning),
    _ServiceStat('Outros', 10, AppColors.grey),
  ];

  double get _maxBarValue =>
      _ultimos6Meses.fold(0, (m, b) => b.value > m ? b.value : m);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: SingleChildScrollView(
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

            // ── KPI Cards ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Faturamento total',
                    value: 'R\$ ${_fmt(_totalReceita)}',
                    icon: Icons.attach_money,
                    color: AppColors.primary,
                    sub: 'desde o início',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Este mês',
                    value: 'R\$ ${_fmt(_receitaMes)}',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    sub: '+12% vs mês anterior',
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
                    value: 'R\$ ${_ticketMedio.toStringAsFixed(2)}',
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFF6366F1),
                    sub: 'por atendimento',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Agendamentos',
                    value: '$_agendamentosTotal',
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.warning,
                    sub: '$_agendamentosMes este mês',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Avaliação média ───────────────────────────────────
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
                              _avaliacaoMedia.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '/ 5.0  •  $_totalAvaliacoes avaliações',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      final full = i < _avaliacaoMedia.floor();
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

            // ── Gráfico de barras (últimos 6 meses) ───────────────
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
                      children: _ultimos6Meses.map((b) {
                        final ratio = b.value / _maxBarValue;
                        final isLast = b == _ultimos6Meses.last;
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isLast)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'R\$${_fmt(b.value)}',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: AppColors.primary,
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
                                            ? AppColors.primary
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
                                            ? AppColors.primary
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

            const SizedBox(height: 20),

            // ── Distribuição de serviços ───────────────────────────
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
                  ..._servicos.map((s) {
                    final pct = s.count /
                        _servicos.fold(0, (sum, x) => sum + x.count);
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
                              value: pct,
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

            const SizedBox(height: 20),

            // ── Estimativa próximo mês ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
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
                          'R\$ ${_fmt(_receitaMes * 1.12)}',
                          style: const TextStyle(
                              fontSize: 22,
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
          ],
        ),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark)),
          const SizedBox(height: 1),
          Text(sub,
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
