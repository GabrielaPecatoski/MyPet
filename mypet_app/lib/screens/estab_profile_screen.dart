import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/mypet_app_bar.dart';

class EstabProfileScreen extends StatefulWidget {
  const EstabProfileScreen({super.key});
  @override
  State<EstabProfileScreen> createState() => _EstabProfileScreenState();
}

class _EstabProfileScreenState extends State<EstabProfileScreen> {
  String? _photoPath;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _photoPath = picked.path);
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.user != null) {
          auth.updateUser(auth.user!.copyWith(photoPath: picked.path));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final photo = _photoPath ?? user?.photoPath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card info estabelecimento
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
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage:
                              photo != null ? FileImage(File(photo)) : null,
                          child: photo == null
                              ? const Icon(Icons.store,
                                  size: 36, color: AppColors.primary)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Estabelecimento',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.dark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '',
                      style: const TextStyle(fontSize: 13, color: AppColors.grey)),
                  if (user?.phone != null && user!.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(user.phone,
                        style:
                            const TextStyle(fontSize: 13, color: AppColors.grey)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu
            Container(
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
              child: Column(
                children: [
                  _item(Icons.person_outline, 'Editar Perfil',
                      () => Navigator.pushNamed(context, '/edit-profile')),
                  _div(),
                  _item(Icons.shopping_bag_outlined, 'Meus Produtos', () {}),
                  _div(),
                  _item(Icons.history_outlined, 'Histórico',
                      () => Navigator.pushNamed(context, '/history')),
                  _div(),
                  _item(Icons.notifications_outlined, 'Notificações',
                      () => Navigator.pushNamed(context, '/notifications')),
                  _div(),
                  _item(Icons.help_outline_rounded, 'Ajuda',
                      () => Navigator.pushNamed(context, '/estab-help')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sair
            GestureDetector(
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout,
                        color: AppColors.danger, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sair',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Versão 1.0.0',
                style: TextStyle(color: AppColors.grey, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: AppColors.dark, size: 22),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.dark)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );

  Widget _div() => const Divider(
      height: 1, indent: 16, endIndent: 16, color: AppColors.divider);
}
