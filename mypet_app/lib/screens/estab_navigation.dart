import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'estab_home_screen.dart';
import 'estab_agenda_screen.dart';
import 'produtos_screen.dart';
import 'estab_avaliacoes_screen.dart';
import 'estab_profile_screen.dart';

class EstabNavigation extends StatefulWidget {
  const EstabNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<EstabNavigation> createState() => _EstabNavigationState();
}

class _EstabNavigationState extends State<EstabNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

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
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        items: estabNavItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
