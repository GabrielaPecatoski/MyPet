import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/notifications_provider.dart';
import '../services/push_notification_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'agenda_screen.dart';
import 'home_screen.dart';
import 'pets_screen.dart';
import 'produtos_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
    // Polling de 60 s como fallback para quando o SSE não estiver disponível (web).
    _notifTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadNotifCount(),
    );
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    context.read<NotificationsProvider>().stopStream();
    super.dispose();
  }

  void _initNotifications() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final notif = context.read<NotificationsProvider>();
    // 1. Busca contagem atual do servidor.
    notif.loadUnreadCount(token: auth.token!, userId: auth.user!.id);
    // 2. Abre SSE para atualizações em tempo real.
    notif.startStream(token: auth.token!, userId: auth.user!.id);
    // 3. Registra token FCM para push (silencia erros se Firebase não configurado).
    PushNotificationService.init(token: auth.token!, userId: auth.user!.id);
  }

  void _loadNotifCount() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    context.read<NotificationsProvider>().loadUnreadCount(
          token: auth.token!,
          userId: auth.user!.id,
        );
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
    final unread = context.watch<NotificationsProvider>().unreadCount;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        items: clientNavItems,
        onTap: _onTabTap,
        badges: unread > 0 ? {0: unread} : {},
      ),
    );
  }
}
