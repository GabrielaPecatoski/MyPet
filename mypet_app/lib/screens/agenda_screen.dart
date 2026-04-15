import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../widgets/mypet_app_bar.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _proximos = [
    AppointmentModel(
      id: '1',
      petName: 'Rex',
      petBreed: 'Golden Retriever',
      petAge: 3,
      serviceName: 'Banho',
      establishmentName: 'Pet Shop Amor & Carinho',
      establishmentAddress: 'Rua das Flores, 123',
      date: DateTime(2026, 3, 17),
      time: '14:00',
      status: 'CONFIRMED',
      price: 50,
    ),
    AppointmentModel(
      id: '2',
      petName: 'Rex',
      petBreed: 'Golden Retriever',
      petAge: 3,
      serviceName: 'Banho',
      establishmentName: 'Pet Shop Amor & Carinho',
      establishmentAddress: 'Rua das Flores, 123',
      date: DateTime(2026, 3, 24),
      time: '14:00',
      status: 'PENDING',
      price: 50,
    ),
  ];

  final _pendentes = [
    AppointmentModel(
      id: '3',
      petName: 'Rex',
      petBreed: 'Golden Retriever',
      petAge: 3,
      serviceName: 'Tosa',
      establishmentName: 'PetCare Express',
      establishmentAddress: 'Rua Nova, 789',
      date: DateTime(2026, 4, 5),
      time: '10:00',
      status: 'PENDING',
      price: 75,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                const Tab(text: 'Próximos'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pendentes'),
                      if (_pendentes.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_pendentes.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AppointmentList(appointments: _proximos),
                _AppointmentList(appointments: _pendentes, showActions: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final bool showActions;

  const _AppointmentList({required this.appointments, this.showActions = false});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: AppColors.greyLight),
            SizedBox(height: 12),
            Text('Nenhum agendamento',
                style: TextStyle(color: AppColors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: appointments.length,
      itemBuilder: (ctx, i) => _AppointmentCard(
        appointment: appointments[i],
        showActions: showActions,
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showActions;

  const _AppointmentCard({required this.appointment, required this.showActions});

  Color get _statusColor {
    switch (appointment.status) {
      case 'CONFIRMED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'CANCELLED':
      case 'REJECTED':
        return AppColors.danger;
      case 'COMPLETED':
        return AppColors.grey;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.pets, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.petName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark)),
                    Text(
                        '${appointment.petBreed} • ${appointment.petAge} anos',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on_outlined, appointment.establishmentName),
          const SizedBox(height: 4),
          _infoRow(Icons.calendar_today_outlined,
              '${appointment.date.day.toString().padLeft(2, '0')}/${appointment.date.month.toString().padLeft(2, '0')}/${appointment.date.year}'),
          const SizedBox(height: 4),
          _infoRow(Icons.access_time, appointment.time),
          const SizedBox(height: 6),
          Text(
            'Valor: R\$ ${appointment.price.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.dark),
          ),
          if (showActions) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Ver detalhes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey,
                      side: const BorderSide(color: AppColors.greyLight),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
        ],
      );
}
