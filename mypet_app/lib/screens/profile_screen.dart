import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/mypet_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        auth.updateUser(auth.user!.copyWith(photoPath: picked.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final photo = user?.photoPath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Card usuário ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: photo != null
                              ? FileImage(File(photo))
                              : null,
                          child: photo == null
                              ? const Icon(Icons.person,
                                  size: 32, color: AppColors.primary)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Usuário',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppColors.dark)),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.grey)),
                        if (user?.phone != null &&
                            user!.phone.isNotEmpty)
                          Text(user.phone,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Menu ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _item(Icons.person_outline, 'Editar Perfil',
                      () => Navigator.pushNamed(context, '/edit-profile')),
                  _div(),
                  _item(Icons.favorite_outline, 'Meus Pets', () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (r) => false,
                        arguments: 3);
                  }),
                  _div(),
                  _item(Icons.history, 'Histórico',
                      () => Navigator.pushNamed(context, '/history')),
                  _div(),
                  _item(Icons.notifications_outlined, 'Notificações',
                      () => Navigator.pushNamed(context, '/notifications')),
                  _div(),
                  _item(Icons.help_outline, 'Ajuda', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppColors.danger, size: 20),
                  SizedBox(width: 6),
                  Text('Sair',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Versão 1.0.0',
                style: TextStyle(color: AppColors.grey, fontSize: 13)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: AppColors.dark, size: 22),
        title:
            Text(label, style: const TextStyle(fontSize: 15, color: AppColors.dark)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );

  Widget _div() => const Divider(
      height: 1, indent: 16, endIndent: 16, color: AppColors.divider);
}
