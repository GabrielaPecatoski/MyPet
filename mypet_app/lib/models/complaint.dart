class ComplaintModel {
  final String id;
  final String userId;
  final String userName;
  final String establishmentId;
  final String? bookingId;
  final String subject;
  final String description;
  final String category;
  final String status;
  final String? response;
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.establishmentId,
    this.bookingId,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    this.response,
    required this.createdAt,
  });

  bool get isPendente => status == 'PENDENTE';

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? 'Usuário',
        establishmentId: json['establishmentId'] as String? ?? '',
        bookingId: json['bookingId'] as String?,
        subject: json['subject'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDENTE',
        response: json['response'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
