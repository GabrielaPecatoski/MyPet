import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_profile_provider.dart';
import '../widgets/app_image.dart';

class DriverCorridasScreen extends StatefulWidget {
  const DriverCorridasScreen({super.key});

  @override
  State<DriverCorridasScreen> createState() => _DriverCorridasScreenState();
}

class _DriverCorridasScreenState extends State<DriverCorridasScreen> {
  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<DriverProfileProvider>();
    if (auth.token == null) return;
    if (provider.driver == null && auth.user?.cpf != null) {
      await provider.load(token: auth.token!, cpf: auth.user!.cpf!);
    }
    if (!mounted) return;
    if (provider.online) {
      await provider.loadAvailableRides(token: auth.token!);
    }
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<DriverProfileProvider>();
    if (auth.token == null || !provider.online) return;
    await provider.loadAvailableRides(token: auth.token!);
  }

  Future<void> _accept(AppointmentModel ride) async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<DriverProfileProvider>();
    if (auth.token == null) return;
    final err = await provider.acceptRide(token: auth.token!, bookingId: ride.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Corrida aceita! Confira na sua agenda.'),
      backgroundColor: err == null ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProfileProvider>();
    final estabId = provider.driver?.establishmentId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(provider.online),
            Expanded(
              child: !provider.online
                  ? _message(
                      Icons.toggle_off_outlined,
                      'Você está offline',
                      'Fique online na aba Início para receber corridas.')
                  : provider.loadingRides && provider.availableRides.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.driver))
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: AppColors.driver,
                          child: provider.availableRides.isEmpty
                              ? ListView(children: [
                                  const SizedBox(height: 80),
                                  _message(
                                      Icons.local_taxi_outlined,
                                      'Nenhuma corrida disponível',
                                      'Assim que surgir um transporte na sua região ele aparece aqui.'),
                                ])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  itemCount: provider.availableRides.length,
                                  itemBuilder: (_, i) => _RideCard(
                                    ride: provider.availableRides[i],
                                    isLinked: estabId != null &&
                                        provider.availableRides[i]
                                                .establishmentId ==
                                            estabId,
                                    dateLabel: _dateLabel(
                                        provider.availableRides[i].date),
                                    onAccept: () =>
                                        _accept(provider.availableRides[i]),
                                  ),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _header(bool online) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route, color: AppColors.driver, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MY PET · MOTORISTA',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey,
                          letterSpacing: 0.8)),
                  Text('Corridas',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (online ? AppColors.success : AppColors.grey)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: online ? AppColors.success : AppColors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(online ? 'Online' : 'Offline',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: online ? AppColors.success : AppColors.grey)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _message(IconData icon, String title, String subtitle) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.greyLight),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.dark)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _RideCard extends StatelessWidget {
  final AppointmentModel ride;
  final bool isLinked;
  final String dateLabel;
  final VoidCallback onAccept;

  const _RideCard({
    required this.ride,
    required this.isLinked,
    required this.dateLabel,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
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
                backgroundImage: appImageProvider(ride.petPhotoUrl),
                child: (ride.petPhotoUrl == null || ride.petPhotoUrl!.isEmpty)
                    ? const Icon(Icons.pets, color: AppColors.driver, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.petName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.dark)),
                    Text(ride.serviceName,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey)),
                  ],
                ),
              ),
              if (isLinked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Seu estabelecimento',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.greyLight),
          const SizedBox(height: 10),
          if (ride.establishmentName.isNotEmpty)
            _row(Icons.store_outlined, ride.establishmentName),
          if (ride.establishmentAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            _row(Icons.location_on_outlined, ride.establishmentAddress),
          ],
          const SizedBox(height: 4),
          _row(Icons.access_time, dateLabel),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline,
                  size: 16, color: Colors.white),
              label: const Text('Aceitar corrida',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.driver,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
        Icon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.grey))),
      ]);
}
