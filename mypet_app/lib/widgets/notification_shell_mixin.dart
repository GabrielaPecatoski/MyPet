import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../services/push_notification_service.dart';

/// Inicializa o stream/badge de notificações para qualquer shell de navegação
/// (vet, estabelecimento, motorista). Replica a lógica do MainNavigation:
/// contagem inicial + SSE em tempo real + polling de 60 s como fallback.
///
/// Uso: `with NotificationShellMixin`, chamar `startNotifications()` no
/// initState e `stopNotifications()` no dispose.
mixin NotificationShellMixin<T extends StatefulWidget> on State<T> {
  Timer? _notifTimer;
  // Referência capturada para uso seguro no dispose (não dá pra ler o provider
  // via context depois que o widget é desativado).
  NotificationsProvider? _notif;

  void startNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
    _notifTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _loadNotifCount(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notif = context.read<NotificationsProvider>();
  }

  void stopNotifications() {
    _notifTimer?.cancel();
    _notif?.stopStream();
  }

  void _initNotifications() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final notif = context.read<NotificationsProvider>();
    notif.loadUnreadCount(token: auth.token!, userId: auth.user!.id);
    notif.startStream(token: auth.token!, userId: auth.user!.id);
    PushNotificationService.init(token: auth.token!, userId: auth.user!.id);
  }

  void _loadNotifCount() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    context.read<NotificationsProvider>().loadUnreadCount(
          token: auth.token!,
          userId: auth.user!.id,
        );
  }
}
