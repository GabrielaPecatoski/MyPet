import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/mypet_app_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MyPetAppBar(showBack: false),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const CircleAvatar(radius:30, backgroundColor: Color(0xFF607D8B), child: Icon(Icons.person, color: Colors.white, size:32)),
            const SizedBox(width:14),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Salsicha', style: TextStyle(fontWeight: FontWeight.w700, fontSize:17)),
              Text('Salsicha@example.com', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
              Text('(11) 98765-4321', style: TextStyle(color: AppColors.textSecondary, fontSize:13)),
            ]),
          ]),
        ),
        const SizedBox(height:12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            _menuItem(Icons.person_outline, 'Editar Perfil', onTap: () => Navigator.pushNamed(context, '/edit-profile')),
            const Divider(height:1, indent:52),
            _menuItem(Icons.favorite_outline, 'Meus Pets', onTap: () => Navigator.pushNamed(context, '/add-pet')),
            const Divider(height:1, indent:52),
            _menuItem(Icons.history, 'Historico', onTap: () => Navigator.pushNamed(context, '/history')),
            const Divider(height:1, indent:52),
            _menuItem(Icons.notifications_none, 'Notificacoes', onTap: () => Navigator.pushNamed(context, '/notifications')),
            const Divider(height:1, indent:52),
            _menuItem(Icons.help_outline, 'Ajuda', onTap: () {}),
          ]),
        ),
        const SizedBox(height:20),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.logout, color: AppColors.danger, size:20),
            const SizedBox(width:6),
            const Text('Sair', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize:15)),
          ]),
        ),
        const SizedBox(height:20),
        const Text('Versao 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize:12)),
      ])),
    );
  }

  static Widget _menuItem(IconData icon, String label, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size:22),
      title: Text(label, style: const TextStyle(fontSize:15)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size:20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal:16, vertical:2),
    );
  }
}
