import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'agenda_screen.dart';
import 'produtos_screen.dart';
import 'pets_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final _screens = const [
    HomeScreen(),
    AgendaScreen(),
    ProdutosScreen(),
    PetsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        items: clientNavItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
