import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
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
