import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_profile_provider.dart';

class DriverInicioScreen extends StatefulWidget {
  const DriverInicioScreen({super.key});

  @override
  State<DriverInicioScreen> createState() => _DriverInicioScreenState();
}

class _DriverInicioScreenState extends State<DriverInicioScreen> {
  bool _online = false;

  static const _orange = Color(0xFFF97316);
  static const _orangeDark = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user?.cpf == null) return;
    await context
        .read<DriverProfileProvider>()
        .load(token: auth.token!, cpf: auth.user!.cpf!);
  }

  bool get _hasPhotos {
    if (kIsWeb) return true;
    final profilePhoto = context.read<AuthProvider>().user?.photoPath;
    final vehiclePhoto = context.read<DriverProfileProvider>().vehiclePhotoPath;
    return profilePhoto != null && vehiclePhoto != null;
  }

  void _tryGoOnline() {
    final driver = context.read<DriverProfileProvider>().driver;
    if (!_online && (driver == null || !driver.isAtivo)) {
      final msg = driver == null
          ? 'Complete seu cadastro de motorista antes de ficar online.'
          : driver.isPendente
              ? 'Aguardando aprovação do administrador para ficar online.'
              : 'Seu cadastro não está ativo. Contate o administrador.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    if (!_hasPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Adicione sua foto de perfil e a foto do veículo na aba Perfil para ficar online.')),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    setState(() => _online = !_online);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driverProfile = context.watch<DriverProfileProvider>();
    final driver = driverProfile.driver;
    final vehiclePhotoPath = driverProfile.vehiclePhotoPath;
    final top = MediaQuery.of(context).padding.top;

    if (driverProfile.loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: _orange)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: _orange,
        child: ListView(
          padding: EdgeInsets.fromLTRB(0, top, 0, 24),
          children: [
            _topHeader(auth),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (!_hasPhotos) ...[
                    _fotosAlertCard(),
                    const SizedBox(height: 14),
                  ],
                  _statusCard(),
                  const SizedBox(height: 14),
                  if (driver != null) _vehicleCard(driver, vehiclePhotoPath),
                  if (driver == null) _semPerfilCard(),
                  const SizedBox(height: 14),
                  _statsCard(),
                  const SizedBox(height: 14),
                  _emptyRides(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topHeader(AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_orangeDark, _orange],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo branca.png',
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MY PET · MOTORISTA',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.8)),
                  Text(
                    auth.user?.name.split(' ').first ?? 'Motorista',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _tryGoOnline,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _online
                              ? const Color(0xFF4ADE80)
                              : Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _online ? 'Online' : 'Offline',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statItem('R\$ 0,00', 'Hoje', Icons.attach_money_rounded),
              _statDivider(),
              _statItem('0', 'Corridas', Icons.route_outlined),
              _statDivider(),
              _statItem('0h', 'Online', Icons.access_time_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      );

  Widget _statDivider() =>
      Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25));

  Widget _fotosAlertCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: AppColors.warning, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fotos obrigatórias pendentes',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.warning)),
                  SizedBox(height: 2),
                  Text(
                      'Adicione sua foto de perfil e a foto do veículo na aba Perfil para ficar online.',
                      style: TextStyle(fontSize: 11, color: AppColors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.warning, size: 18),
          ],
        ),
      );

  Widget _statusCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VOCÊ ESTÁ',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey,
                        letterSpacing: 0.8)),
                const SizedBox(height: 2),
                Text(
                  _online ? 'Online' : 'Offline',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _online ? AppColors.success : AppColors.grey),
                ),
                Text(
                  _online
                      ? 'Recebendo corridas na sua região'
                      : (_hasPhotos
                          ? 'Toque para ficar online'
                          : 'Adicione as fotos para ficar online'),
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _tryGoOnline,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: _online
                      ? AppColors.success
                      : (_hasPhotos
                          ? AppColors.greyLight
                          : AppColors.greyLight.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment:
                      _online ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _hasPhotos
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _vehicleCard(DriverModel d, String? vehiclePhotoPath) {
    final vehicleIcon = switch (d.vehicleType) {
      'MOTO' => Icons.two_wheeler,
      'VAN' => Icons.airport_shuttle,
      _ => Icons.directions_car,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(vehicleIcon, color: _orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.vehicleModel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.dark)),
                Text('${d.vehiclePlate} · ${d.vehicleTypeLabel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ),
          if (vehiclePhotoPath != null && !kIsWeb)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.file(File(vehiclePhotoPath), fit: BoxFit.cover),
              ),
            )
          else if (d.isAssociado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_outlined, size: 12, color: _orange),
                  SizedBox(width: 4),
                  Text('Associado',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _orange)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greyLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                d.isAtivo ? 'Ativo' : 'Inativo',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: d.isAtivo ? AppColors.success : AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }

  Widget _semPerfilCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: const Row(
          children: [
            Icon(Icons.directions_car_outlined, color: AppColors.grey, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Perfil de motorista não cadastrado.\nComplete seu cadastro via "Perfil".',
                style: TextStyle(color: AppColors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _statsCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomStat(Icons.star_rounded, AppColors.warning, '—', 'Avaliação'),
            Container(width: 1, height: 36, color: AppColors.greyLight),
            _bottomStat(Icons.check_circle_outline, AppColors.success, '—', 'Aceitação'),
            Container(width: 1, height: 36, color: AppColors.greyLight),
            _bottomStat(Icons.route, _orange, '0', 'Corridas'),
          ],
        ),
      );

  Widget _bottomStat(IconData icon, Color color, String value, String label) =>
      Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.grey)),
        ],
      );

  Widget _emptyRides() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.local_taxi_outlined, size: 28, color: _orange),
            ),
            const SizedBox(height: 12),
            const Text('Nenhuma corrida ainda',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.dark)),
            const SizedBox(height: 4),
            Text(
              _online
                  ? 'Aguardando solicitações de corrida...'
                  : 'Fique online para receber corridas.',
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
