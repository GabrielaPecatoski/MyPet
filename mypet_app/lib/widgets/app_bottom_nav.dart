import 'package:flutter/material.dart';
import '../core/colors.dart';

class BottomNavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const clientNavItems = [
  BottomNavItemData(icon: Icons.home_outlined,           activeIcon: Icons.home,            label: 'Home'),
  BottomNavItemData(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today,  label: 'Agenda'),
  BottomNavItemData(icon: Icons.shopping_bag_outlined,   activeIcon: Icons.shopping_bag,    label: 'Carrinho'),
  BottomNavItemData(icon: Icons.favorite_outline,        activeIcon: Icons.favorite,        label: 'Pets'),
  BottomNavItemData(icon: Icons.person_outline,          activeIcon: Icons.person,          label: 'Perfil'),
];

const estabNavItems = [
  BottomNavItemData(icon: Icons.home_outlined,           activeIcon: Icons.home,            label: 'Home'),
  BottomNavItemData(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today,  label: 'Agenda'),
  BottomNavItemData(icon: Icons.shopping_bag_outlined,   activeIcon: Icons.shopping_bag,    label: 'Produtos'),
  BottomNavItemData(icon: Icons.star_outline,            activeIcon: Icons.star,            label: 'Avaliações'),
  BottomNavItemData(icon: Icons.bar_chart_outlined,      activeIcon: Icons.bar_chart,       label: 'Estatísticas'),
  BottomNavItemData(icon: Icons.person_outline,          activeIcon: Icons.person,          label: 'Perfil'),
];

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavItemData> items;
  final void Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? AppColors.primary : AppColors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? AppColors.primary : AppColors.grey,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
