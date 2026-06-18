import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'driver_inicio_screen.dart';
import 'driver_rides_screen.dart';
import 'driver_ganhos_screen.dart';
import 'driver_historico_screen.dart';
import 'driver_perfil_screen.dart';

const driverNavItems = [
  BottomNavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Início'),
  BottomNavItemData(
      icon: Icons.route_outlined,
      activeIcon: Icons.route,
      label: 'Corridas'),
  BottomNavItemData(
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments,
      label: 'Ganhos'),
  BottomNavItemData(
      icon: Icons.history_rounded,
      activeIcon: Icons.history_rounded,
      label: 'Histórico'),
  BottomNavItemData(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Perfil'),
];

class DriverNavigation extends StatefulWidget {
  const DriverNavigation({super.key});

  @override
  State<DriverNavigation> createState() => _DriverNavigationState();
}

class _DriverNavigationState extends State<DriverNavigation> {
  int _index = 0;

  static final _screens = [
    const DriverInicioScreen(),
    const DriverCorridasScreen(),
    const DriverGanhosScreen(),
    const DriverHistoricoScreen(),
    const DriverPerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: AppColors.driver,
          onPrimary: Colors.white,
        ),
      ),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _index,
          items: driverNavItems,
          onTap: (i) => setState(() => _index = i),
          activeColor: AppColors.driver,
        ),
      ),
    );
  }
}
