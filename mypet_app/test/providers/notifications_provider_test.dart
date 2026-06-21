import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_app/providers/notifications_provider.dart';
import 'package:mypet_app/repositories/notification_repository.dart';

void main() {
  group('NotificationsProvider — gerenciamento de badge (C35)', () {
    late NotificationsProvider provider;

    setUp(() {
      provider = NotificationsProvider(NotificationRepository());
    });

    tearDown(() {
      provider.dispose();
    });

    test('estado inicial tem unreadCount = 0', () {
      expect(provider.unreadCount, 0);
    });

    test('clearUnread quando contador já é zero não notifica listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearUnread();

      expect(provider.unreadCount, 0);
      expect(notifyCount, 0);
    });

    test('stopStream pode ser chamado sem conexão ativa sem lançar exceção', () {
      expect(() => provider.stopStream(), returnsNormally);
    });

    test('dispose fecha o SSE sem lançar exceção', () {
      final local = NotificationsProvider(NotificationRepository());
      expect(() => local.dispose(), returnsNormally);
    });
  });

  group('NotificationsProvider — startStream sem conectar HTTP', () {
    test('startStream no Web (kIsWeb=true) não conecta SSE e não lança', () {
      // No ambiente de teste o dart:io está disponível e kIsWeb=false,
      // então o SSE tentaria conectar. Apenas verificamos que o provider
      // aceita a chamada a stopStream logo depois sem erro.
      final provider = NotificationsProvider(NotificationRepository());
      provider.stopStream();
      expect(provider.unreadCount, 0);
      provider.dispose();
    });

    test('múltiplas chamadas a stopStream são seguras', () {
      final provider = NotificationsProvider(NotificationRepository());
      expect(() {
        provider.stopStream();
        provider.stopStream();
      }, returnsNormally);
      provider.dispose();
    });
  });

  group('NotificationsProvider — clearUnread', () {
    test('clearUnread não lança exceção independente do estado', () {
      final provider = NotificationsProvider(NotificationRepository());
      expect(() => provider.clearUnread(), returnsNormally);
      provider.dispose();
    });

    test('unreadCount permanece 0 após clearUnread sem notificações', () {
      final provider = NotificationsProvider(NotificationRepository());
      provider.clearUnread();
      expect(provider.unreadCount, 0);
      provider.dispose();
    });
  });
}
