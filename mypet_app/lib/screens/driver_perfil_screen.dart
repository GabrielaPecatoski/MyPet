import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../services/driver_service.dart';
import '../services/storage_service.dart';
import '../widgets/mypet_app_bar.dart';

class DriverPerfilScreen extends StatefulWidget {
  const DriverPerfilScreen({super.key});
  @override
  State<DriverPerfilScreen> createState() => _DriverPerfilScreenState();
}

class _DriverPerfilScreenState extends State<DriverPerfilScreen> {
  DriverModel? _driver;
  bool _loading = true;
  String? _vehiclePhotoPath;

  static const _orange = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user?.cpf == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        DriverService.findByCpf(token: auth.token!, cpf: auth.user!.cpf!),
        StorageService.getVehiclePhoto(),
      ]);
      setState(() {
        _driver = results[0] as DriverModel?;
        _vehiclePhotoPath = results[1] as String?;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickProfilePhoto() async {
    if (kIsWeb) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      final auth = context.read<AuthProvider>();
      auth.updateUser(auth.user!.copyWith(photoPath: picked.path));
      setState(() {});
    }
  }

  Future<void> _pickVehiclePhoto() async {
    if (kIsWeb) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      await StorageService.saveVehiclePhoto(picked.path);
      setState(() => _vehiclePhotoPath = picked.path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto do veículo salva!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'Motorista';
    final email = auth.user?.email ?? '';
    final phone = auth.user?.phone ?? '';
    final photo = auth.user?.photoPath;

    final hasProfile = photo != null && !kIsWeb;
    final hasVehicle = _vehiclePhotoPath != null && !kIsWeb;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _orange))
          : RefreshIndicator(
              onRefresh: _load,
              color: _orange,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickProfilePhoto,
                                child: CircleAvatar(
                                  radius: 34,
                                  backgroundColor:
                                      _orange.withValues(alpha: 0.12),
                                  backgroundImage:
                                      (photo != null && !kIsWeb) ? FileImage(File(photo)) : null,
                                  child: !hasProfile
                                      ? const Icon(Icons.person,
                                          size: 34, color: _orange)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickProfilePhoto,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _orange,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: AppColors.dark)),
                                const SizedBox(height: 3),
                                if (email.isNotEmpty)
                                  Text(email,
                                      style: const TextStyle(
                                          fontSize: 13, color: AppColors.grey)),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(phone,
                                      style: const TextStyle(
                                          fontSize: 13, color: AppColors.grey)),
                                ],
                                if (_driver != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_driver!.vehicleTypeLabel} · ${_driver!.vehiclePlate}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _orange,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          _statItem(Icons.route, _orange, '0', 'Corridas'),
                          _divider(),
                          _statItem(Icons.star_rounded, AppColors.warning, '—',
                              'Avaliação'),
                          _divider(),
                          _statItem(Icons.calendar_month_outlined,
                              AppColors.grey, '—', 'Membro'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Fotos obrigatórias',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.dark)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (hasProfile && hasVehicle
                                          ? AppColors.success
                                          : AppColors.warning)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  hasProfile && hasVehicle
                                      ? 'Completo'
                                      : 'Pendente',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: hasProfile && hasVehicle
                                          ? AppColors.success
                                          : AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Necessárias para ficar online e aceitar corridas.',
                            style: TextStyle(fontSize: 11, color: AppColors.grey),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                  child: _photoCard(
                                label: 'Foto de perfil',
                                icon: Icons.person_outline,
                                photoPath: photo,
                                hasPhoto: hasProfile,
                                onTap: _pickProfilePhoto,
                              )),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _photoCard(
                                label: 'Foto do veículo',
                                icon: Icons.directions_car_outlined,
                                photoPath: _vehiclePhotoPath,
                                hasPhoto: hasVehicle,
                                onTap: _pickVehiclePhoto,
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        children: [
                          _menuTile(
                            icon: Icons.badge_outlined,
                            iconColor: _orange,
                            label: 'Documentos do veículo',
                            subtitle: _driver != null
                                ? 'CNH: ${_driver!.cnh} · ${_driver!.vehiclePlate}'
                                : 'CNH, CRLV',
                            onTap: () {},
                          ),
                          _div(),
                          _menuTile(
                            icon: Icons.account_balance_outlined,
                            iconColor: AppColors.success,
                            label: 'Conta bancária',
                            subtitle: 'Configure sua chave PIX',
                            onTap: () {},
                          ),
                          _div(),
                          _menuTile(
                            icon: Icons.star_rate_outlined,
                            iconColor: AppColors.warning,
                            label: 'Avaliações recebidas',
                            subtitle: 'Nenhuma avaliação ainda',
                            onTap: () {},
                          ),
                          _div(),
                          _menuTile(
                            icon: Icons.settings_outlined,
                            iconColor: AppColors.grey,
                            label: 'Configurações',
                            subtitle: 'Notificações, privacidade',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () async {
                        await auth.logout();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: AppColors.danger, size: 20),
                          SizedBox(width: 8),
                          Text('Sair',
                              style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Versão 1.0.0',
                        style: TextStyle(color: AppColors.grey, fontSize: 12)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _photoCard({
    required String label,
    required IconData icon,
    required String? photoPath,
    required bool hasPhoto,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: hasPhoto ? Colors.transparent : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPhoto
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.warning.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(photoPath!), fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        color: Colors.black38,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 28,
                        color: AppColors.warning.withValues(alpha: 0.7)),
                    const SizedBox(height: 6),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    const Text('Toque para adicionar',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.greyLight)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String value, String label) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.dark)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.greyLight);

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.dark)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 11.5, color: AppColors.grey)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.greyLight, size: 20),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );

  Widget _div() => const Divider(
      height: 1, indent: 68, endIndent: 0, color: AppColors.divider);
}
