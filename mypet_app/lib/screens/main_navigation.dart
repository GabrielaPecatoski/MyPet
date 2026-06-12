import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'agenda_screen.dart';
import 'loja_screen.dart';
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
    LojaScreen(),
    PetsScreen(),
    ProfileScreen(),
  ];

  void _onTabTap(int i) {
    setState(() => _currentIndex = i);
    if (i == 1) {
      final auth = context.read<AuthProvider>();
      if (auth.token != null && auth.user != null) {
        context.read<BookingProvider>().loadUserBookings(
              token: auth.token!,
              userId: auth.user!.id,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _ClientSidebar(
              selectedIndex: _currentIndex,
              onTap: _onTabTap,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        items: clientNavItems,
        onTap: _onTabTap,
      ),
    );
  }
}

class _ClientSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _ClientSidebar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 70,
            color: const Color(0xFF7B3FF2),
            child: Center(
              child: Image.asset(
                'assets/images/logo branca.png',
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (int index) => onTap(index),
              labelType: NavigationRailLabelType.all,
              destinations: clientNavItems
                  .asMap()
                  .entries
                  .map((e) => NavigationRailDestination(
                        icon: Icon(e.value.icon),
                        selectedIcon: Icon(e.value.activeIcon),
                        label: Text(e.value.label),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
