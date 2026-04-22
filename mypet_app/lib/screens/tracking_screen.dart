import 'dart:async';
import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../widgets/mypet_app_bar.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _currentStep = 2; // simula "Em Andamento"
  int _elapsedMin = 0;
  Timer? _timer;

  static const _steps = [
    _Step('Aguardando', 'Seu pet está na fila de atendimento',
        Icons.hourglass_empty),
    _Step('Preparando', 'Preparando tudo para o atendimento',
        Icons.medical_services_outlined),
    _Step('Em Andamento', 'Seu pet está sendo atendido',
        Icons.pets),
    _Step('Finalizando', 'Últimos ajustes e cuidados',
        Icons.check_circle_outline),
    _Step('Concluído', 'Serviço finalizado! Pode buscar seu pet',
        Icons.verified),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.85, end: 1.15).animate(_pulseCtrl);

    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() => _elapsedMin++);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ap =
        ModalRoute.of(context)?.settings.arguments as AppointmentModel?;
    if (ap != null) {
      setState(() {
        switch (ap.status) {
          case 'PENDENTE':
            _currentStep = 0;
            break;
          case 'CONFIRMADO':
            _currentStep = 2;
            break;
          case 'CONCLUIDO':
            _currentStep = 4;
            break;
          default:
            _currentStep = 2;
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  double get _progressValue => (_currentStep + 1) / _steps.length;

  @override
  Widget build(BuildContext context) {
    final ap =
        ModalRoute.of(context)?.settings.arguments as AppointmentModel?;
    final dateStr = ap != null
        ? '${ap.date.year}-${ap.date.month.toString().padLeft(2, '0')}-${ap.date.day.toString().padLeft(2, '0')} às ${ap.time}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MapView(pulseAnim: _pulseAnim),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.pets,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _steps[_currentStep].title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.dark),
                            ),
                            Text(
                              _steps[_currentStep].subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (_currentStep < 4)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${25 + _elapsedMin} min',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressValue,
                      backgroundColor: AppColors.greyLight,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(_progressValue * 100).round()}% concluído',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Acompanhamento',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.dark)),
                  const SizedBox(height: 16),
                  ...List.generate(_steps.length, (i) {
                    final done = i < _currentStep;
                    final current = i == _currentStep;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: done
                                      ? AppColors.success
                                      : current
                                          ? AppColors.primary
                                          : AppColors.greyLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  done
                                      ? Icons.check
                                      : _steps[i].icon,
                                  color: (done || current)
                                      ? Colors.white
                                      : AppColors.grey,
                                  size: 14,
                                ),
                              ),
                              if (i < _steps.length - 1)
                                Container(
                                    width: 2,
                                    height: 28,
                                    color: done
                                        ? AppColors.success
                                        : AppColors.greyLight),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _steps[i].title,
                                  style: TextStyle(
                                    fontWeight: current
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 14,
                                    color: (done || current)
                                        ? AppColors.dark
                                        : AppColors.grey,
                                  ),
                                ),
                                Text(
                                  _steps[i].subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: (done || current)
                                        ? AppColors.grey
                                        : AppColors.greyLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (ap != null)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalhes do Serviço',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryLight,
                          child: const Icon(Icons.pets,
                              color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ap.petName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.dark)),
                              if (ap.petBreed.isNotEmpty)
                                Text(
                                    '${ap.petBreed}${ap.petAge > 0 ? ' • ${ap.petAge} anos' : ''}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _detail('Serviço', ap.serviceName),
                    const Divider(height: 20, color: AppColors.greyLight),
                    Row(
                      children: [
                        Expanded(child: _detail('Data e Hora', dateStr)),
                        Text(
                          'R\$ ${ap.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fotos do Atendimento',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.dark)),
                  const SizedBox(height: 12),
                  if (_currentStep < 2)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: const Center(
                        child: Text(
                          'As fotos aparecerão durante o atendimento',
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: 4,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: i < 3
                            ? Container(
                                color: AppColors.primaryLight,
                                child: const Icon(Icons.pets,
                                    color: AppColors.primary, size: 36),
                              )
                            : Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Text('+10',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (ap != null)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ap.establishmentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark)),
                    const SizedBox(height: 4),
                    if (ap.establishmentAddress.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(ap.establishmentAddress,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.grey)),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.phone_outlined, size: 16),
                            label: const Text('Ligar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dark,
                              side: const BorderSide(color: AppColors.greyLight),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.message_outlined,
                                size: 16, color: Colors.white),
                            label: const Text('Mensagem',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark)),
        ],
      );
}

class _MapView extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _MapView({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primaryLight,
          ],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: _MapGridPainter(),
            size: Size.infinite,
          ),
          Center(
            child: ScaleTransition(
              scale: pulseAnim,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on,
                    color: Colors.white, size: 30),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, __) => Container(
                width: 80 * pulseAnim.value,
                height: 80 * pulseAnim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary
                        .withValues(alpha: 0.3 * (2 - pulseAnim.value)),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location,
                        size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Localização em tempo real',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Step {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Step(this.title, this.subtitle, this.icon);
}
