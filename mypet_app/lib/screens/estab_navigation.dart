import 'package:flutter/material.dart';
import '../core/colors.dart';
import 'estab_home_screen.dart';
import 'estab_agenda_screen.dart';
import 'produtos_screen.dart';
import 'estab_avaliacoes_screen.dart';
import 'estab_profile_screen.dart';

class EstabNavigation extends StatefulWidget {
  const EstabNavigation({super.key});
  @override
  State<EstabNavigation> createState() => _EstabNavigationState();
}

class _EstabNavigationState extends State<EstabNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    EstabHomeScreen(),
    EstabAgendaScreen(),
    ProdutosScreen(),
    EstabAvaliacoesScreen(),
    EstabProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home,
                    label: 'Home', index: 0, current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today,
                    label: 'Agenda', index: 1, current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag,
                    label: 'Produtos', index: 2, current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.star_outline, activeIcon: Icons.star,
                    label: 'Avaliações', index: 3, current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.person_outline, activeIcon: Icons.person,
                    label: 'Perfil', index: 4, current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final void Function(int) onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label,
      required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.grey, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.primary : AppColors.grey,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
