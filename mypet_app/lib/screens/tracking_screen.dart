import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../widgets/mypet_app_bar.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const _steps = [
    _Step('Aguardando confirmação',
        'Aguardando resposta do estabelecimento', Icons.hourglass_empty),
    _Step('Em atendimento',
        'Seu pet está sendo atendido', Icons.pets),
    _Step('Concluído',
        'Serviço finalizado! Pode buscar seu pet', Icons.verified),
  ];

  AppointmentModel? _ap;
  String? _token;

  int _currentStep = 0;
  int _elapsedMin = 0;
  bool _serviceStarted = false;
  bool _isCancelled = false;
  String? _cancelLabel;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final ap =
        ModalRoute.of(context)?.settings.arguments as AppointmentModel?;
    if (ap == null) return;
    _token = context.read<AuthProvider>().token;
    final shouldStop =
        ['CONCLUIDO', 'CANCELADO', 'RECUSADO'].contains(ap.status);
    setState(() {
      _ap = ap;
      _applyStatus(ap.status, ap.date);
    });
    if (!shouldStop) _startPolling();
  }

  void _applyStatus(String status, DateTime date) {
    switch (status) {
      case 'PENDENTE':
        _currentStep = 0;
        _isCancelled = false;
      case 'CONFIRMADO':
        _currentStep = 1;
        _isCancelled = false;
        final diff = DateTime.now().difference(date).inMinutes;
        _serviceStarted = diff >= 0;
        _elapsedMin = diff.abs().clamp(0, 999);
      case 'CONCLUIDO':
        _currentStep = 2;
        _isCancelled = false;
      case 'CANCELADO':
        _isCancelled = true;
        _cancelLabel = 'Agendamento cancelado';
      case 'RECUSADO':
        _isCancelled = true;
        _cancelLabel = 'Agendamento recusado pelo estabelecimento';
      default:
        _currentStep = 0;
        _isCancelled = false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refresh() async {
    if (_ap == null || _token == null) return;
    try {
      final data = await ApiService.get(
        '/bookings/${_ap!.id}',
        token: _token,
      );
      final updated =
          AppointmentModel.fromJson(data as Map<String, dynamic>);
      if (!mounted) return;
      if (updated.status != _ap!.status) {
        final shouldStop =
            ['CONCLUIDO', 'CANCELADO', 'RECUSADO'].contains(updated.status);
        setState(() {
          _ap = updated;
          _applyStatus(updated.status, updated.date);
        });
        if (shouldStop) _stopPolling();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  double get _progressValue => (_currentStep + 1) / _steps.length;

  Future<void> _openChat() async {
    if (_ap == null) return;
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    if (auth.token == null) return;
    try {
      final conv = await chat.openOrCreateConversation(
        bookingId: _ap!.id,
        clientId: auth.user?.id ?? _ap!.userId,
        clientName: auth.user?.name ?? _ap!.userName,
        establishmentId: _ap!.establishmentId,
        establishmentName: _ap!.establishmentName,
        token: auth.token!,
      );
      if (!mounted) return;
      Navigator.pushNamed(context, '/chat', arguments: conv);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o chat'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = _ap ??
        (ModalRoute.of(context)?.settings.arguments as AppointmentModel?);
    final dateStr = ap != null
        ? '${ap.date.year}-${ap.date.month.toString().padLeft(2, '0')}-${ap.date.day.toString().padLeft(2, '0')} às ${ap.time}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      floatingActionButton: (_ap != null && _ap!.isConfirmado)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: const Text('Mensagem',
                  style: TextStyle(color: Colors.white)),
              onPressed: _openChat,
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isCancelled)
              _buildCancelledBanner()
            else
              _buildStatusCard(),

            if (!_isCancelled) ...[
              const SizedBox(height: 8),
              _buildStepsList(),
            ],

            if (ap != null) ...[
              const SizedBox(height: 8),
              _buildDetailsCard(ap, dateStr),
              const SizedBox(height: 8),
              _buildEstablishmentCard(ap),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: AppColors.danger.withValues(alpha: 0.06),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined,
                color: AppColors.danger, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            _cancelLabel ?? 'Agendamento encerrado',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Entre em contato com o estabelecimento para mais informações.',
            style: TextStyle(fontSize: 13, color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
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
              if (_currentStep == 1)
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
                        _serviceStarted
                            ? 'há $_elapsedMin min'
                            : 'Em $_elapsedMin min',
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
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_progressValue * 100).round()}% concluído',
            style:
                const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList() {
    return Container(
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
                          done ? Icons.check : _steps[i].icon,
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
                              : AppColors.greyLight,
                        ),
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
    );
  }

  Widget _buildDetailsCard(AppointmentModel ap, String dateStr) {
    return Container(
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
    );
  }

  Widget _buildEstablishmentCard(AppointmentModel ap) {
    return Container(
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
          if (ap.establishmentAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
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
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark)),
        ],
      );
}

class _Step {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Step(this.title, this.subtitle, this.icon);
}
