import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_app/models/conversation_model.dart';
import 'package:mypet_app/models/message_model.dart';

void main() {
  final createdAt = DateTime(2026, 6, 14, 9, 0, 0);
  final lastMsgAt = DateTime(2026, 6, 14, 10, 30, 0);

  final lastMsgJson = {
    'id': 'msg-last',
    'conversationId': 'conv-1',
    'senderId': 'client-1',
    'senderRole': 'CLIENTE',
    'content': 'Última mensagem',
    'readAt': null,
    'createdAt': lastMsgAt.toIso8601String(),
  };

  final baseJson = {
    'id': 'conv-1',
    'bookingId': 'booking-1',
    'clientId': 'client-1',
    'clientName': 'João',
    'establishmentId': 'vendor-1',
    'establishmentName': 'Pet Shop XYZ',
    'lastMessageAt': lastMsgAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'lastMessage': lastMsgJson,
    'unreadCount': 3,
  };

  group('ConversationModel.fromJson', () {
    test('parses all fields correctly', () {
      final conv = ConversationModel.fromJson(baseJson);
      expect(conv.id, 'conv-1');
      expect(conv.bookingId, 'booking-1');
      expect(conv.clientId, 'client-1');
      expect(conv.clientName, 'João');
      expect(conv.establishmentId, 'vendor-1');
      expect(conv.establishmentName, 'Pet Shop XYZ');
      expect(conv.lastMessageAt?.hour, 10);
      expect(conv.lastMessage, isNotNull);
      expect(conv.lastMessage!.content, 'Última mensagem');
      expect(conv.unreadCount, 3);
    });

    test('defaults unreadCount to 0 when absent', () {
      final json = {...baseJson}..remove('unreadCount');
      final conv = ConversationModel.fromJson(json);
      expect(conv.unreadCount, 0);
    });

    test('handles null lastMessage', () {
      final json = {...baseJson, 'lastMessage': null};
      final conv = ConversationModel.fromJson(json);
      expect(conv.lastMessage, isNull);
    });

    test('handles missing fields gracefully', () {
      final conv = ConversationModel.fromJson({});
      expect(conv.id, '');
      expect(conv.unreadCount, 0);
    });
  });

  group('ConversationModel.partnerName', () {
    test('returns establishmentName when I am the client', () {
      final conv = ConversationModel.fromJson(baseJson);
      expect(conv.partnerName('client-1'), 'Pet Shop XYZ');
    });

    test('returns clientName when I am the vendor', () {
      final conv = ConversationModel.fromJson(baseJson);
      expect(conv.partnerName('vendor-1'), 'João');
    });
  });

  group('ConversationModel.copyWith', () {
    test('updates unreadCount', () {
      final conv = ConversationModel.fromJson(baseJson);
      final updated = conv.copyWith(unreadCount: 0);
      expect(updated.unreadCount, 0);
      expect(updated.id, conv.id);
    });

    test('updates lastMessage and lastMessageAt', () {
      final conv = ConversationModel.fromJson(baseJson);
      final newMsg = MessageModel.fromJson({
        ...lastMsgJson,
        'id': 'msg-new',
        'content': 'Nova mensagem',
      });
      final newTime = DateTime(2026, 6, 14, 11, 0, 0);
      final updated = conv.copyWith(lastMessage: newMsg, lastMessageAt: newTime);
      expect(updated.lastMessage!.content, 'Nova mensagem');
      expect(updated.lastMessageAt!.hour, 11);
      expect(updated.clientName, conv.clientName); // unchanged
    });

    test('does not mutate original', () {
      final conv = ConversationModel.fromJson(baseJson);
      conv.copyWith(unreadCount: 99);
      expect(conv.unreadCount, 3);
    });
  });
}
