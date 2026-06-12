import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/vet_profile_provider.dart';
import '../widgets/app_bottom_nav.dart';
import 'vet_home_screen.dart';
import 'vet_appointments_screen.dart';
import 'vet_chamados_screen.dart';
import 'vet_pacientes_screen.dart';
import 'vet_perfil_screen.dart';

const vetNavItems = [
  BottomNavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Início'),
  BottomNavItemData(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Agenda'),
  BottomNavItemData(
      icon: Icons.notification_important_outlined,
      activeIcon: Icons.notification_important,
      label: 'Chamados'),
  BottomNavItemData(
      icon: Icons.pets_outlined,
      activeIcon: Icons.pets,
      label: 'Pacientes'),
  BottomNavItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Perfil'),
];

class VetNavigation extends StatefulWidget {
  const VetNavigation({super.key});

  @override
  State<VetNavigation> createState() => _VetNavigationState();
}

class _VetNavigationState extends State<VetNavigation> {
  int _index = 0;

  static final _screens = [
    const VetHomeScreen(),
    const VetAgendaScreen(),
    const VetChamadosScreen(),
    const VetPacientesScreen(),
    const VetPerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: AppColors.vet,
          onPrimary: Colors.white,
        ),
      ),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _index,
          items: vetNavItems,
          onTap: (i) => setState(() => _index = i),
          badges: {2: context.watch<VetProfileProvider>().pendingCallsCount},
          activeColor: AppColors.vet,
        ),
      ),
    );
  }
}
