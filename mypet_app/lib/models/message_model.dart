class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final String content;
  final DateTime? readAt;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderRole: json['senderRole'] as String? ?? '',
      content: json['content'] as String? ?? '',
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  bool get isRead => readAt != null;

  static const _unset = Object();

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderRole,
    String? content,
    Object? readAt = _unset,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      readAt: identical(readAt, _unset) ? this.readAt : readAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderRole': senderRole,
        'content': content,
        'readAt': readAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
