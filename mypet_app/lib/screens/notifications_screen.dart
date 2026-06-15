import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/mypet_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<NotificationsProvider>().load(auth.user!.id, token: auth.token);
      }
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays == 1) return 'Ontem';
    return '${diff.inDays} dias atrás';
  }

  IconData _icon(String type) {
    switch (type) {
      case 'BOOKING_CONFIRMED':
        return Icons.check_circle_outline;
      case 'BOOKING_REJECTED':
        return Icons.cancel_outlined;
      case 'BOOKING_CANCELLED':
        return Icons.event_busy_outlined;
      case 'BOOKING_COMPLETED':
        return Icons.star_outline;
      case 'NEW_BOOKING':
        return Icons.calendar_today_outlined;
      case 'BOOKING_TODAY_REMINDER':
        return Icons.today_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'BOOKING_CONFIRMED':
      case 'BOOKING_COMPLETED':
        return AppColors.success;
      case 'BOOKING_REJECTED':
      case 'BOOKING_CANCELLED':
        return AppColors.danger;
      case 'NEW_BOOKING':
      case 'BOOKING_TODAY_REMINDER':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        items: clientNavItems,
        onTap: (i) {
          if (i == 4) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (r) => false,
                arguments: i);
          }
        },
      ),
      body: Builder(builder: (context) {
        final provider = context.watch<NotificationsProvider>();
        final auth = context.read<AuthProvider>();
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return RefreshIndicator(
          onRefresh: () => provider.load(auth.user?.id ?? '', token: auth.token),
          color: AppColors.primary,
          child: provider.notifications.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: const Icon(Icons.notifications_none, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text('Nenhuma notificação',
                          style: TextStyle(color: AppColors.dark, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('Você está em dia!',
                          style: TextStyle(color: AppColors.grey, fontSize: 13)),
                    ]),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  itemBuilder: (ctx, i) {
                    final n = provider.notifications[i];
                        final color = _color(n.type);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: n.read
                                ? null
                                : Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.25)),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Icon(_icon(n.type),
                                    color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(n.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.dark)),
                                        ),
                                        if (!n.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(n.body,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.grey,
                                            height: 1.4)),
                                    const SizedBox(height: 6),
                                    Text(_timeAgo(n.createdAt),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        );
      }),
    );
  }
}
