import 'message_model.dart';

class ConversationModel {
  final String id;
  final String bookingId;
  final String clientId;
  final String establishmentId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final MessageModel? lastMessage;

  const ConversationModel({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.establishmentId,
    this.lastMessageAt,
    required this.createdAt,
    this.lastMessage,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      establishmentId: json['establishmentId'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }

  String get otherPartyId => clientId;
}
