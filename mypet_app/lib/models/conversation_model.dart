import 'message_model.dart';

class ConversationModel {
  final String id;
  final String bookingId;
  final String clientId;
  final String clientName;
  final String establishmentId;
  final String establishmentName;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final MessageModel? lastMessage;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.bookingId,
    required this.clientId,
    this.clientName = '',
    required this.establishmentId,
    this.establishmentName = '',
    this.lastMessageAt,
    required this.createdAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      clientId: json['clientId'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      establishmentId: json['establishmentId'] as String? ?? '',
      establishmentName: json['establishmentName'] as String? ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  ConversationModel copyWith({
    String? id,
    String? bookingId,
    String? clientId,
    String? clientName,
    String? establishmentId,
    String? establishmentName,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    MessageModel? lastMessage,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      establishmentId: establishmentId ?? this.establishmentId,
      establishmentName: establishmentName ?? this.establishmentName,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  String partnerName(String myId) =>
      clientId == myId ? establishmentName : clientName;
}
