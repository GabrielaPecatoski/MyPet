import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../widgets/mypet_app_bar.dart';

class EstabProfileScreen extends StatefulWidget {
  const EstabProfileScreen({super.key});
  @override
  State<EstabProfileScreen> createState() => _EstabProfileScreenState();
}

class _EstabProfileScreenState extends State<EstabProfileScreen> {
  String? _photoPath;

  Future<void> _pickOwnerImage() async {
    if (kIsWeb) return;
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

  Future<void> _deleteEstablishment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir estabelecimento',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        content: const Text(
          'Tem certeza? Todos os dados do estabelecimento, serviços e informações serão removidos permanentemente.',
          style: TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<EstablishmentProvider>();
    final ok = await provider.deleteEstablishment(token: auth.token ?? '');

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estabelecimento removido.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await auth.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.error ?? 'Erro ao excluir estabelecimento.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final estab = context.watch<EstablishmentProvider>().establishment;
    final ownerPhoto = _photoPath ?? user?.photoPath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: SingleChildScrollView(
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
                        onTap: _pickOwnerImage,
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage:
                              (!kIsWeb && ownerPhoto != null)
                                  ? FileImage(File(ownerPhoto))
                                  : null,
                          child: (kIsWeb || ownerPhoto == null)
                              ? const Icon(Icons.person,
                                  size: 34, color: AppColors.estab)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickOwnerImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.estab,
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
                        Text(
                          user?.name ?? 'Proprietário',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.dark),
                        ),
                        const SizedBox(height: 3),
                        Text(user?.email ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.grey)),
                        if (user?.phone != null &&
                            user!.phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(user.phone,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.grey)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (estab != null)
              Container(
                padding: const EdgeInsets.all(16),
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
                    _EstabAvatar(imageUrl: estab.imageUrl, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            estab.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.dark),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  estab.typeLabel,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.estab,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          if (estab.address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              estab.address,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.estab, size: 20),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/estab-edit'),
                      tooltip: 'Editar estabelecimento',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _item(Icons.person_outline, 'Editar Perfil',
                      () => Navigator.pushNamed(context, '/edit-profile')),
                  _div(),
                  _item(Icons.store_outlined, 'Editar Estabelecimento',
                      () => Navigator.pushNamed(context, '/estab-edit')),
                  _div(),
                  _item(Icons.location_on_outlined, 'Meus endereços',
                      () => Navigator.pushNamed(context, '/enderecos')),
                  _div(),
                  _item(Icons.local_shipping_outlined, 'Motoristas',
                      () => Navigator.pushNamed(context, '/motoristas')),
                  _div(),
                  _item(Icons.medical_services_outlined, 'Veterinários',
                      () => Navigator.pushNamed(context, '/veterinarios')),
                  _div(),
                  _item(Icons.shopping_bag_outlined, 'Meus Produtos', () {}),
                  _div(),
                  _item(Icons.history_outlined, 'Histórico',
                      () => Navigator.pushNamed(context, '/history')),
                  _div(),
                  _item(Icons.notifications_outlined, 'Notificações',
                      () => Navigator.pushNamed(context, '/notifications')),
                  _div(),
                  _item(Icons.chat_bubble_outline, 'Mensagens',
                      () => Navigator.pushNamed(context, '/conversations')),
                  _div(),
                  _item(Icons.help_outline_rounded, 'Ajuda',
                      () => Navigator.pushNamed(context, '/estab-help')),
                  _div(),
                  _itemDanger(Icons.delete_outline, 'Excluir Estabelecimento',
                      _deleteEstablishment),
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
                  SizedBox(width: 8),
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
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );

  Widget _itemDanger(IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: AppColors.danger, size: 22),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.danger)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.danger, size: 20),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );

  Widget _div() => const Divider(
      height: 1, indent: 16, endIndent: 16, color: AppColors.divider);
}

class _EstabAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  const _EstabAvatar({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image/')) {
        final bytes = base64Decode(url.split(',').last);
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(bytes),
        );
      }
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(url),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryLight,
      child: Icon(Icons.store, size: size * 0.45, color: AppColors.estab),
    );
  }
}
