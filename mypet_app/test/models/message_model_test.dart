import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_app/models/message_model.dart';

void main() {
  final baseTime = DateTime(2026, 6, 14, 10, 30, 0);
  final readTime = DateTime(2026, 6, 14, 10, 35, 0);

  final baseJson = {
    'id': 'msg-1',
    'conversationId': 'conv-1',
    'senderId': 'user-1',
    'senderRole': 'CLIENTE',
    'content': 'Olá!',
    'readAt': null,
    'createdAt': baseTime.toIso8601String(),
  };

  group('MessageModel.fromJson', () {
    test('parses all fields correctly', () {
      final msg = MessageModel.fromJson(baseJson);
      expect(msg.id, 'msg-1');
      expect(msg.conversationId, 'conv-1');
      expect(msg.senderId, 'user-1');
      expect(msg.senderRole, 'CLIENTE');
      expect(msg.content, 'Olá!');
      expect(msg.readAt, isNull);
      expect(msg.createdAt.year, 2026);
    });

    test('parses readAt timestamp', () {
      final json = {...baseJson, 'readAt': readTime.toIso8601String()};
      final msg = MessageModel.fromJson(json);
      expect(msg.readAt, isNotNull);
      expect(msg.readAt!.minute, 35);
    });

    test('handles null/missing fields gracefully', () {
      final msg = MessageModel.fromJson({});
      expect(msg.id, '');
      expect(msg.content, '');
      expect(msg.readAt, isNull);
    });
  });

  group('MessageModel.isRead', () {
    test('returns false when readAt is null', () {
      final msg = MessageModel.fromJson(baseJson);
      expect(msg.isRead, isFalse);
    });

    test('returns true when readAt is set', () {
      final json = {...baseJson, 'readAt': readTime.toIso8601String()};
      final msg = MessageModel.fromJson(json);
      expect(msg.isRead, isTrue);
    });
  });

  group('MessageModel.copyWith', () {
    test('copies with updated readAt', () {
      final msg = MessageModel.fromJson(baseJson);
      final updated = msg.copyWith(readAt: readTime);
      expect(updated.id, msg.id);
      expect(updated.content, msg.content);
      expect(updated.readAt, readTime);
    });

    test('does not mutate original', () {
      final msg = MessageModel.fromJson(baseJson);
      msg.copyWith(content: 'Diferente');
      expect(msg.content, 'Olá!');
    });

    test('copies with updated content only', () {
      final msg = MessageModel.fromJson(baseJson);
      final updated = msg.copyWith(content: 'Nova mensagem');
      expect(updated.content, 'Nova mensagem');
      expect(updated.senderId, msg.senderId);
      expect(updated.readAt, isNull);
    });
  });

  group('MessageModel.toJson', () {
    test('serializes correctly', () {
      final msg = MessageModel.fromJson(baseJson);
      final json = msg.toJson();
      expect(json['id'], 'msg-1');
      expect(json['content'], 'Olá!');
      expect(json['readAt'], isNull);
    });
  });
}
