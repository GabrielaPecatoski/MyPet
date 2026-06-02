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
<<<<<<< HEAD
        onTap: (i) => setState(() => _currentIndex = i),
=======
        onTap: _onTabTap,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
      ),
    );
  }
}
