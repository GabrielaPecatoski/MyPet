import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../widgets/app_bottom_nav.dart';
import 'estab_home_screen.dart';
import 'estab_agenda_screen.dart';
import 'estab_produtos_screen.dart';
import 'estab_avaliacoes_screen.dart';
import 'estab_vendas_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEstablishment());
  }

  Future<void> _loadEstablishment() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) return;
    await context.read<EstablishmentProvider>().loadByOwner(
          token: auth.token!,
          ownerId: auth.user!.id,
          ownerName: auth.user!.name,
          ownerPhone: auth.user!.phone,
        );
  }

  final _screens = const [
    EstabHomeScreen(),
    EstabAgendaScreen(),
    EstabProdutosScreen(),
    EstabAvaliacoesScreen(),
    EstabVendasScreen(),
    EstabProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _EstabSidebar(
              selectedIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
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
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        items: estabNavItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _EstabSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _EstabSidebar({
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
              destinations: estabNavItems
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
