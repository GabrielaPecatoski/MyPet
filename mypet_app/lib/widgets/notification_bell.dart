import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/notifications_provider.dart';

/// Sino de notificações com badge de não lidas, reutilizado nos cabeçalhos de
/// todas as contas (cliente, vet, estabelecimento, motorista). Toca abre a
/// rota `/notifications`.
class NotificationBell extends StatelessWidget {
  final Color iconColor;
  final double iconSize;

  const NotificationBell({
    super.key,
    this.iconColor = Colors.white,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsProvider>().unreadCount;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: iconColor, size: iconSize),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
