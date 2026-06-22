import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_profile_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/mypet_app_bar.dart';

class DriverPerfilScreen extends StatefulWidget {
  const DriverPerfilScreen({super.key});
  @override
  State<DriverPerfilScreen> createState() => _DriverPerfilScreenState();
}

class _DriverPerfilScreenState extends State<DriverPerfilScreen> {
  static const _orange = Color(0xFFF97316);

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

  Future<void> _pickProfilePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = await context.read<DriverProfileProvider>().updateProfilePhoto(
          token: auth.token ?? '',
          photoUrl: dataUrlFromBytes(bytes),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(ok ? 'Foto de perfil salva!' : 'Erro ao salvar foto de perfil'),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickVehiclePhoto() async {
    if (kIsWeb) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      await context
          .read<DriverProfileProvider>()
          .saveVehiclePhoto(picked.path);
      if (!mounted) return;
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
    final driverProfile = context.watch<DriverProfileProvider>();
    final driver = driverProfile.driver;
    final vehiclePhotoPath = driverProfile.vehiclePhotoPath;
    final name = auth.user?.name ?? 'Motorista';
    final email = auth.user?.email ?? '';
    final phone = auth.user?.phone ?? '';
    final profilePhotoUrl = driver?.photoUrl;

    final hasProfile = profilePhotoUrl != null && profilePhotoUrl.isNotEmpty;
    final hasVehicle = vehiclePhotoPath != null && !kIsWeb;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: driverProfile.loading
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
                                      appImageProvider(profilePhotoUrl),
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
                                if (driver != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${driver.vehicleTypeLabel} · ${driver.vehiclePlate}',
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
                                image: appImageProvider(profilePhotoUrl),
                                onTap: _pickProfilePhoto,
                              )),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _photoCard(
                                label: 'Foto do veículo',
                                icon: Icons.directions_car_outlined,
                                image: hasVehicle
                                    ? FileImage(File(vehiclePhotoPath))
                                    : null,
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
                            subtitle: driver != null
                                ? 'CNH: ${driver.cnh} · ${driver.vehiclePlate}'
                                : 'CNH, CRLV',
                            onTap: () => _showDocsSheet(driver),
                          ),
                          _div(),
                          _menuTile(
                            icon: Icons.account_balance_outlined,
                            iconColor: AppColors.success,
                            label: 'Conta bancária',
                            subtitle: driverProfile.hasPix
                                ? '${driverProfile.pixType}: ${driverProfile.pixKey}'
                                : 'Configure sua chave PIX',
                            onTap: () => _showPixSheet(driverProfile),
                          ),
                          _div(),
                          _menuTile(
                            icon: Icons.star_rate_outlined,
                            iconColor: AppColors.warning,
                            label: 'Avaliações recebidas',
                            subtitle: 'Nenhuma avaliação ainda',
                            onTap: _showRatingsSheet,
                          ),
                          _div(),
                          _menuTile(
                            icon: Icons.settings_outlined,
                            iconColor: AppColors.grey,
                            label: 'Configurações',
                            subtitle: 'Notificações, privacidade',
                            onTap: () => _showSettingsSheet(driverProfile),
                          ),
                          _div(),
                          _menuTile(
                            icon: Icons.location_on_outlined,
                            iconColor: AppColors.primary,
                            label: 'Meus endereços',
                            subtitle:
                                '${auth.user?.addresses.length ?? 0} cadastrado(s)',
                            onTap: () =>
                                Navigator.pushNamed(context, '/enderecos'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
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

  Future<void> _pickCnhPhoto() async {
    if (kIsWeb) return;
    final auth = context.read<AuthProvider>();
    final cpf = auth.user?.cpf;
    if (cpf == null) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      await context
          .read<DriverProfileProvider>()
          .saveCnhPhoto(cpf, picked.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto da CNH salva!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showDocsSheet(DriverModel? driver) {
    final cnhPath = context.read<DriverProfileProvider>().cnhPhotoPath;
    final hasCnh = cnhPath != null && !kIsWeb;
    _showSheet(
      title: 'Documentos do veículo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _docRow('CNH', driver?.cnh ?? '—'),
          _docRow('Placa', driver?.vehiclePlate ?? '—'),
          _docRow('Veículo',
              driver == null ? '—' : '${driver.vehicleTypeLabel} · ${driver.vehicleModel}'),
          const SizedBox(height: 16),
          const Text('Foto da CNH',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: AppColors.dark)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _pickCnhPhoto();
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: hasCnh ? Colors.transparent : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasCnh
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.warning.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasCnh
                    ? Image(image: FileImage(File(cnhPath)), fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined,
                              size: 28, color: AppColors.warning),
                          SizedBox(height: 6),
                          Text('Toque para adicionar a CNH',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.grey)),
                        ],
                      ),
              ),
            ),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 8),
            const Text('Disponível apenas no app.',
                style: TextStyle(fontSize: 11, color: AppColors.greyLight)),
          ],
        ],
      ),
    );
  }

  void _showPixSheet(DriverProfileProvider provider) {
    final controller = TextEditingController(text: provider.pixKey ?? '');
    String type = provider.pixType;
    const types = ['CPF', 'CNPJ', 'E-mail', 'Telefone', 'Aleatória'];
    _showSheet(
      title: 'Conta bancária',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tipo de chave PIX',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13, color: AppColors.dark)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in types)
                  ChoiceChip(
                    label: Text(t),
                    selected: type == t,
                    onSelected: (_) => setSheetState(() => type = t),
                    selectedColor: AppColors.success.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                        fontSize: 12.5,
                        color: type == t ? AppColors.success : AppColors.grey,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Chave PIX',
                hintText: 'Informe sua chave',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await provider.savePix(
                      key: controller.text.trim(), type: type);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Chave PIX salva!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: const Text('Salvar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingsSheet() {
    _showSheet(
      title: 'Avaliações recebidas',
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.star_outline_rounded,
                size: 48, color: AppColors.greyLight),
            SizedBox(height: 12),
            Text('Nenhuma avaliação ainda',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.dark)),
            SizedBox(height: 4),
            Text('Complete corridas para receber avaliações dos clientes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(DriverProfileProvider provider) {
    _showSheet(
      title: 'Configurações',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _settingTile(
              'Notificações de novas corridas',
              provider.settingEnabled('notifRides'),
              (v) {
                provider.setSetting('notifRides', v);
                setSheetState(() {});
              },
            ),
            _settingTile(
              'Sons e vibração',
              provider.settingEnabled('sounds'),
              (v) {
                provider.setSetting('sounds', v);
                setSheetState(() {});
              },
            ),
            _settingTile(
              'Mostrar meu telefone ao cliente',
              provider.settingEnabled('showPhone'),
              (v) {
                provider.setSetting('showPhone', v);
                setSheetState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: _orange,
        contentPadding: EdgeInsets.zero,
        title: Text(label,
            style: const TextStyle(fontSize: 13.5, color: AppColors.dark)),
      );

  Widget _docRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.grey)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark)),
            ),
          ],
        ),
      );

  void _showSheet({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.dark)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _photoCard({
    required String label,
    required IconData icon,
    required ImageProvider? image,
    required VoidCallback onTap,
  }) {
    final hasPhoto = image != null;
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
                    Image(image: image, fit: BoxFit.cover),
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
