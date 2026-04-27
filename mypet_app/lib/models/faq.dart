class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;
  final bool active;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
    required this.active,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        id: json['id'] ?? '',
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
        category: json['category'] ?? 'Geral',
        order: json['order'] ?? 0,
        active: json['active'] ?? true,
      );
}

class UserQuestion {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String question;
  final String? answer;
  final String status; // PENDENTE | RESPONDIDA | FECHADA
  final DateTime createdAt;
  final DateTime? answeredAt;

  const UserQuestion({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.question,
    this.answer,
    required this.status,
    required this.createdAt,
    this.answeredAt,
  });

  factory UserQuestion.fromJson(Map<String, dynamic> json) => UserQuestion(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        userName: json['userName'] ?? '',
        userRole: json['userRole'] ?? 'CLIENTE',
        question: json['question'] ?? '',
        answer: json['answer'],
        status: json['status'] ?? 'PENDENTE',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        answeredAt: json['answeredAt'] != null
            ? DateTime.tryParse(json['answeredAt'])
            : null,
      );
}
